# Declarative health checks

`flake-health` runs a Nix-generated manifest of standalone monitoring checks;
`flake-health-alert` is the single scheduled daily reporter (05:00, ntfy).
Both are built by `modules/nixos/health/default.nix` and installed on every host
with `teq.nixos.health.enable` (default: `teq.nixos.enable`).

## Define a check

Service modules contribute checks through `teq.nixos.health.checks`:

```nix
teq.nixos.health.checks.cache-endpoint = {
  command = [
    "${pkgs.monitoring-plugins}/bin/check_http"
    "-H" "cache.example.org" "-S" "--sni"
    "-u" "/nix-cache-info"
  ];
  timeout = 20; # seconds
  report = true; # false = interactive diagnostics only, never in the daily report
  remote = false; # true = only with --remote, never in the daily report
};
```

Each command is an argument list, executed without a shell. Exit codes are 0 OK,
1 warning, 2 critical, and 3 unknown. A check prints its diagnostic to stdout;
plugin performance data is split at the first pipe and preserved in the JSON
`perfdata` field, separately from `message`. Missing executables,
timeouts, empty output, and other exit codes become UNKNOWN. Four checks can run
concurrently. CRITICAL takes precedence over UNKNOWN in the overall status.

Names are stable incident IDs. Host modules can disable individual checks with
`teq.nixos.health.checks.<name>.enable = false`. The generated manifest contains
only enabled checks. Do not put credentials in command arguments or diagnostic
output; manifests are public store files and reports may be posted.

## Which checks run when

| Invocation | Includes |
| --- | --- |
| `flake-health` (`just health`) | every local check, `report = false` ones marked `[interactive only]` |
| `flake-health --remote` | the above plus `remote = true` checks (ssh to other hosts) |
| `flake-health --scheduled` / the daily reporter | only `report = true`, never `remote` |
| `flake-health --check ID` | that ID if it is eligible under the other flags; otherwise an UNKNOWN result explaining the exclusion |

`--json` emits `{"version": 1, "complete": bool, "excluded": {id: reason}, "results": [...]}`.
`complete = false` means the runner itself failed (manifest unreadable, internal
error); the reporter then knows that absent checks were not evaluated. `excluded`
lists every manifest entry skipped by policy and why. Each result carries
`deferred`: true when a probe exited OK but printed the perfdata token
`deferred=1`, meaning "no alert warranted, outcome not established yet". Only the
`job.*` probes use it today (boot/resume grace, a running job, a running retry).

`repo.dirty` and `repo.sync` are `report = false`: a working tree that is ahead of
origin is normal during the day and would make the build host's daily report
never go quiet. `repo.inputs` (lockfile commit age) stays in the daily report.

## Coverage and policy

| Owner | Checks |
| --- | --- |
| Health | Disk space/inodes, failed units, NTP synchronization, reboot/profile mismatch |
| Build server | Persistent update success, dirty repository*, primary remote tracking-ref divergence*, lockfile commit age, published closures, running-vs-published over ssh (remote) |
| Cache pull | Persistent pull success, build-server SSH connectivity |
| Nix configuration | Persistent GC/auto-upgrade success when enabled, configured GitHub token, local cache HTTP/TLS |
| Notify | ntfy HTTP/TLS |

\* interactive only.

Cache endpoint IDs are `cache-<first hostname label>` (e.g. `net.http.cache-thoughtful`).
If two caches share a first label the full hostname is used; duplicate names fail
evaluation with an assertion rather than overwriting a check.

SSH banner success alone does not prove cache-pull authorization; the pull job's
completion provides stronger evidence. The GitHub probe checks the invoking
user's Nix configuration (root for the daily report, you for `just health`); on
these hosts both read the same `/run/agenix/gh` include, but the probe does not
claim to validate what the `flake-update` job (user `teq`) sees.

Disk policy is configurable per mount:

```nix
teq.nixos.health.disks."/boot" = { warning = "100"; critical = "70"; };
teq.nixos.health.disks."/nix" = { warning = "5120"; critical = "1024"; };
```

These are free MiB, with `/boot` headroom for a roughly 66 MiB kernel/initrd.
Percent strings such as `"10%"` are also supported. Each severity has one space
threshold, avoiding ambiguous absolute/percentage combinations. Inode thresholds
remain 10% warning and 5% critical. Missing configured mounts are errors (`-E`).
See the [plugin contract](https://www.monitoring-plugins.org/doc/man/check_disk.html).

An old lockfile commit warns about input freshness independently of job success;
it does not prove a failed update. Repo synchronization uses existing local
tracking refs and explicitly reports that it did not fetch them.

## Jobs: scheduled oneshot services

```nix
teq.nixos.health.jobs.flake-update = {
  maxSuccessAge = 26 * 3600; # wall-clock seconds, including sleep
  maxRuntime = 6 * 3600; # awake execution time
  bootGrace = 3600; # seconds after boot
  resumeGrace = 1800; # seconds after the last resume from sleep; 0 disables
};
```

The job name defaults to the service/timer basename; `unit` can override it.
The module adds a StateDirectory and an ExecStartPost success recorder to the
existing oneshot service. A successful no-op run also refreshes the record
(which is why `repo.inputs` exists separately). Records are atomically replaced
in `/var/lib/health-job-<name>/success.json`, owned by the service user. This
repo already persists `/var/lib` on impermanent hosts. No records are created
until the changed units are deployed and run; until then `job.*` is UNKNOWN.

Evaluation order, so that grace never hides a real problem:

1. service or timer not loaded -> CRITICAL
2. timer not active -> CRITICAL
3. service running: awake runtime over `maxRuntime` -> CRITICAL, else OK
4. last attempt failed -> CRITICAL
5. success record younger than `maxSuccessAge` -> OK
6. uptime under `bootGrace` -> OK (catch-up pending)
7. last resume from sleep under `resumeGrace` -> OK (catch-up pending)
8. no record -> UNKNOWN; stale record -> WARNING

Grace is bounded by `graceLimit` (default 86400). Boot and resume grace apply
only while the staleness is at most `maxSuccessAge + graceLimit`:

- with a success record, staleness is the record's age;
- with no record, staleness is measured from the job's **first attempt**, a
  durable baseline (`/var/lib/health-job-<name>/baseline.json`) that the unit
  writes itself in `ExecStartPre` the first time it ever starts and never
  rewrites. It survives reboots, so a job that keeps failing to record success
  cannot renew its allowance by rebooting;
- with neither (the unit has never started since the health module was
  deployed), staleness falls back to time since boot (CLOCK_BOOTTIME, sleep
  counts). This is the only per-boot allowance left and it ends the first time
  the timer fires the unit.

Past the bound the overdue WARNING or missing UNKNOWN is reported even if every
daily report happens minutes after a boot or resume. Interactive checks and
reporter dry-runs never write any of these files: the success record and the
baseline are written only by the job unit; delivery state only by a real
reporter run after a successful POST.
With the defaults (26 h + 24 h) a laptop that sleeps every night and whose job
stops succeeding is deferred on the first morning report and reported on the
second, about 52 hours after the last success. Note what grace does *not* do: it does not
look at how overdue the job is within the bound, so a job 40 hours stale that
was checked five minutes after waking is deferred, not reported, until the
bound is crossed.

Resume evidence is the journal's `SD_MESSAGE_SLEEP_STOP` entry
(`MESSAGE_ID=8811e6df2a8e40f58a94cea26f8ebf14`) for the current boot, read with
`journalctl -b`. systemd-sleep's own unit timestamps are not usable: the oneshot
unit is garbage-collected after each sleep and `systemctl show` returns nothing.
If the journal is unreadable or no resume happened this boot, resume grace is
simply not applied. bubblegum sets both graces to 3600 in `hosts/bubblegum.nix`.

## Daily report state

`flake-health-alert` runs `flake-health --scheduled --json`, compares non-OK
results with `/var/lib/flake-health/delivered.json`
(`{"version": 2, "incidents": {...}}`) and posts:

- `NEW` / `CHANGED` / `ONGOING` for every current non-OK check (ongoing incidents
  repeat daily on purpose: one morning message, nothing forgotten)
- `RESOLVED <id>` only when that check ran in this report and returned a
  confirmed OK (not deferred)
- `DEFERRED <id>` when the check returned a deferred OK and an incident already
  exists: the incident is kept unchanged (grace or a running retry is not
  recovery). A deferred OK with no existing incident prints nothing.
- `DROPPED <id>: <reason>` once when the runner completed and the check was not
  evaluated (excluded by policy, disabled, or gone from the manifest), then it
  is forgotten. The reason comes from the runner's `excluded` map.
- `RUNNER INCOMPLETE: <message>` when the runner did **not** complete. This is
  a condition of that run, not an incident id, so it is never stored and never
  DROPPED later. Every previously delivered incident is listed `UNVERIFIED` and
  kept exactly as it was; nothing is dropped or reset to NEW. The message is
  still posted (severity UNKNOWN) so a broken runner is visible.

State is written only after a successful POST; a failed POST leaves the previous
state intact and the unit fails (notify-fail fires). Concurrent real runs are
serialized with a lock. `--dry-run` prints the message, never posts, never
writes state.

First report after promotion: `delivered.json` does not exist, so every current
incident is `NEW`. The Bash-era `last-nonok` file in the same directory is
ignored and the message carries a one-line NOTE saying so. Any `delivered.json`
that is not version 2 is likewise not trusted (NOTE + everything NEW); it is
never interpreted as prior successful delivery.

## Try it (no deployment needed)

```sh
nix build 'path:.#nixosConfigurations.thoughtful.config.teq.nixos.health.package' --out-link result-health
./result-health/bin/flake-health
./result-health/bin/flake-health --remote
./result-health/bin/flake-health --scheduled --json
./result-health/bin/flake-health --check disk.root
./result-health/bin/flake-health-alert --dry-run --state-dir /tmp/health-state
```

Tests:

```sh
nix build 'path:.#checks.x86_64-linux.health' --no-link   # also part of nix flake check / just check
```

Until new files are tracked, use the `path:.` reference so Nix includes the
complete working tree.

## Not ported from the Bash version, on purpose

- Journal keyword grep of a unit's last invocation (`error:`, `HTTP error`):
  it matched build-log noise as often as real failures. Job success records +
  `repo.inputs` cover the case it was written for (silent 401 no-op updates).
- nixpkgs age parsed from the store path name: superseded by `repo.inputs`.
- Change-based suppression (post only when the non-OK set changed): replaced by
  daily ONGOING lines, which cannot let an incident be forgotten.
- `--checkmk` line output: `--json` carries the same fields (`id`, `state`,
  `message`, `perfdata`, `report`); a Checkmk renderer is a follow-up.

## Follow-up work

Per-stage deployment records (fetched/evaluated/built/switched revisions),
storage-result aggregation for SMART and scrub, a journal watcher with a
remembered cursor (mk_logwatch style), and an external heartbeat.
