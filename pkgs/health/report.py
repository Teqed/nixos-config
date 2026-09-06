"""Daily incident summary. Persist delivered state only after a successful POST.

State file: <state-dir>/delivered.json = {"version": 2, "incidents": {id: result}}.
A missing file, or one that is not version 2, is never treated as prior delivery:
every current incident is reported as NEW and a note says why. The Bash-era
"last-nonok" file in the same directory is ignored (and mentioned once).

Transitions (per check id, given the previous delivered incidents):
  non-OK result            -> NEW / CHANGED / ONGOING, kept in state
  OK, not deferred          -> RESOLVED if previously an incident, removed from state
  OK, deferred              -> DEFERRED if previously an incident (kept, unchanged); otherwise silent
  absent, runner complete   -> DROPPED once with the runner's exclusion reason, removed from state
  runner incomplete         -> RUNNER INCOMPLETE line (a condition of the run, not an incident id);
                               every delivered incident is listed UNVERIFIED and kept unchanged
"""
import argparse
import fcntl
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import urllib.request

from runner import LABELS, OUTPUT_VERSION, severity

STATE_VERSION = 2


def load_state(state_file):
    """Return (incidents, note). incidents is {} whenever prior delivery cannot be trusted."""
    legacy = state_file.parent / "last-nonok"
    if not state_file.exists():
        if legacy.exists():
            return {}, "Legacy flake-health-alert state found and ignored; all current incidents are shown as NEW."
        return {}, None
    try:
        data = json.loads(state_file.read_text())
        if data.get("version") == STATE_VERSION and isinstance(data.get("incidents"), dict):
            return data["incidents"], None
    except (OSError, ValueError, AttributeError):
        pass
    return {}, "Previous incident state was unreadable or from an older format; all current incidents are shown as NEW."


def validate(document):
    """Reject any document whose control fields do not follow the runner contract, before state is touched."""
    if not isinstance(document, dict) or document.get("version") != OUTPUT_VERSION:
        raise ValueError("Unsupported runner output")
    if not isinstance(document.get("complete"), bool):
        raise ValueError("Invalid health report: complete must be a boolean")
    excluded = document.get("excluded")
    if not isinstance(excluded, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in excluded.items()):
        raise ValueError("Invalid health report: excluded must map ids to reasons")
    results = document.get("results")
    if not isinstance(results, list) or not results:
        raise ValueError("Invalid health report: results missing")
    seen = set()
    for r in results:
        if not isinstance(r, dict) or not isinstance(r.get("id"), str) or type(r.get("state")) is not int or r["state"] not in LABELS \
                or not isinstance(r.get("message"), str) or not isinstance(r.get("perfdata", ""), str) \
                or not isinstance(r.get("deferred", False), bool) or not isinstance(r.get("report", True), bool):
            raise ValueError("Invalid health report: malformed result")
        if r["id"] in seen:
            raise ValueError("Invalid health report: duplicate result id " + r["id"])
        seen.add(r["id"])
    return document


def summarize(document, previous):
    """Return (incidents_to_save, body_lines)."""
    if not document.get("complete"):
        # Execution failed: nothing was evaluated. Report the failure as a condition of this run,
        # never as an incident id, and carry every delivered incident forward untouched.
        lines = [f"RUNNER INCOMPLETE: {r['message']}" for r in document["results"]]
        lines.extend(f"UNVERIFIED {LABELS[previous[name]['state']]} {name}: not re-evaluated, runner incomplete"
                     for name in sorted(previous))
        return dict(previous), "\n".join(lines)
    results = {r["id"]: r for r in document["results"]}
    excluded = document.get("excluded", {})
    current, lines = {}, []
    for name, result in sorted(results.items()):
        state, was = result["state"], previous.get(name)
        if state != 0:
            current[name] = result
            status = "NEW" if was is None else ("CHANGED" if was["state"] != state else "ONGOING")
            lines.append(f"{status} {LABELS[state]} {name}: {result['message']}")
        elif result.get("deferred"):
            if was is not None:
                current[name] = was
                lines.append(f"DEFERRED {LABELS[was['state']]} {name}: {result['message']}")
        elif was is not None:
            lines.append(f"RESOLVED {name}")
    for name in sorted(previous.keys() - results.keys()):
        lines.append(f"DROPPED {name}: {excluded.get(name, 'no longer in the manifest')}")
    return current, "\n".join(lines)


def deliver(args, state_file):
    result = subprocess.run([args.runner, "--scheduled", "--json"], capture_output=True, text=True, timeout=300)
    if result.returncode not in (0, 1, 2, 3):
        raise RuntimeError("Health runner failed")
    document = validate(json.loads(result.stdout))
    previous, note = load_state(state_file)
    current, body = summarize(document, previous)
    if not body:
        print("All healthy; no notification")
        return
    if note:
        body = "NOTE: " + note + "\n\n" + body
    level = severity(list(document["results"]) + list(current.values()))
    title = f"{socket.gethostname()} health: {LABELS[level]}"
    if args.dry_run:
        print(title + "\n" + body)
        return
    request = urllib.request.Request(
        os.environ["NTFY_URL"].rstrip("/") + "/" + os.environ["NTFY_TOPIC"],
        data=body.encode(), headers={"Title": title, "Priority": "high" if level == 2 else "default"})
    with urllib.request.urlopen(request, timeout=30) as response:
        response.read()
    with tempfile.NamedTemporaryFile(mode="w", dir=state_file.parent, delete=False) as output:
        json.dump({"version": STATE_VERSION, "incidents": current}, output)
        temporary = output.name
    os.replace(temporary, state_file)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runner", required=True)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--state-dir", default="/var/lib/flake-health")
    args = parser.parse_args()
    directory = Path(args.state_dir)
    if args.dry_run:
        deliver(args, directory / "delivered.json")
    else:
        directory.mkdir(parents=True, exist_ok=True)
        with (directory / "lock").open("w") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            deliver(args, directory / "delivered.json")


if __name__ == "__main__":
    main()
