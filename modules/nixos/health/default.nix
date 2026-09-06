{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.teq.nixos.health;
  notify = config.teq.nixos.notify;
  checkType = lib.types.submodule {
    options = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
      };
      command = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Executable and arguments; no shell expansion. Exit codes: 0 OK, 1 warning, 2 critical, 3 unknown.";
      };
      timeout = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Execution timeout in seconds.";
      };
      remote = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Run only with --remote; never part of the scheduled report.";
      };
      report = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Include in the scheduled daily report. false = interactive diagnostics only.";
      };
    };
  };
  checks = lib.filterAttrs (_: check: check.enable) cfg.checks;
  jobs = lib.filterAttrs (_: job: job.enable) cfg.jobs;
  recordPath = name: "/var/lib/health-job-${name}/success.json";
  baselinePath = name: "/var/lib/health-job-${name}/baseline.json";
  manifest = pkgs.writeText "health-checks.json" (builtins.toJSON checks);
  package = pkgs.runCommand "flake-health" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
    mkdir -p $out/bin $out/lib
    cp ${../../../pkgs/health/runner.py} $out/lib/runner.py
    cp ${../../../pkgs/health/report.py} $out/lib/report.py
    makeWrapper ${pkgs.python3}/bin/python3 $out/bin/flake-health \
      --add-flags "$out/lib/runner.py --manifest ${manifest}"
    makeWrapper ${pkgs.python3}/bin/python3 $out/bin/flake-health-alert \
      --add-flags "$out/lib/report.py --runner $out/bin/flake-health" \
      --set-default NTFY_URL ${lib.escapeShellArg notify.url} \
      --set-default NTFY_TOPIC ${lib.escapeShellArg notify.topic}
  '';
in
{
  options.teq.nixos.health = {
    alert = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Daily scheduled report: runs every check marked report and posts NEW/CHANGED/ONGOING/RESOLVED/DROPPED incidents to ntfy.";
      };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "05:00";
        description = "After the nightly update chain has finished.";
      };
    };
    endpoints = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Named HTTP endpoints; HTTPS endpoints also get a certificate check.";
    };
    disks = lib.mkOption {
      description = "Per-mount free-space thresholds: MiB or a percentage, one threshold per severity.";
      default = lib.genAttrs (lib.filter (mount: builtins.hasAttr mount config.fileSystems) [
        "/"
        "/boot"
        "/nix"
      ]) (_: { });
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              warning = lib.mkOption {
                type = lib.types.str;
                default = if name == "/boot" then "100" else "5120";
              };
              critical = lib.mkOption {
                type = lib.types.str;
                default = if name == "/boot" then "70" else "1024";
              };
            };
          }
        )
      );
    };
    jobs = lib.mkOption {
      default = { };
      description = "Scheduled oneshot services whose successful completion is recorded persistently.";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              unit = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Service/timer basename without suffix.";
              };
              maxSuccessAge = lib.mkOption {
                type = lib.types.ints.positive;
                default = 93600;
                description = "Maximum wall-clock seconds since success.";
              };
              maxRuntime = lib.mkOption {
                type = lib.types.ints.positive;
                default = 7200;
                description = "Maximum awake runtime in seconds.";
              };
              bootGrace = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 3600;
                description = "Suppress missing/stale success during these seconds after boot; failures are never suppressed.";
              };
              resumeGrace = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 1800;
                description = "Suppress missing/stale success during these seconds after the last resume from sleep (journal evidence); failures are never suppressed. 0 disables.";
              };
              graceLimit = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 86400;
                description = "Boot/resume grace stops applying once the success record is older than maxSuccessAge + graceLimit seconds (or, with no record, once the host has been up that long including sleep). Bounds how long repeated grace can hide a job that stopped succeeding.";
              };
            };
          }
        )
      );
    };
    checks = lib.mkOption {
      type = lib.types.attrsOf checkType;
      default = { };
      description = "Named runtime checks contributed by service modules.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = package;
      description = "flake-health (runner) and flake-health-alert (daily reporter).";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions =
      (lib.mapAttrsToList (name: check: {
        assertion =
          builtins.match "[A-Za-z0-9_.-]+" name != null
          && check.command != [ ]
          && lib.hasPrefix "/" (lib.head check.command);
        message = "Health check ${name} requires a stable alphanumeric ID and an absolute executable path.";
      }) checks)
      ++ lib.mapAttrsToList (name: job: {
        assertion =
          builtins.match "[A-Za-z0-9_-]+" name != null
          && builtins.match "[A-Za-z0-9_-]+" job.unit != null
          && (config.systemd.services.${job.unit}.serviceConfig.Type or "") == "oneshot";
        message = "Health job ${name} must reference an existing oneshot service and use simple unit/record names.";
      }) jobs;
    environment.systemPackages = [ package ];

    systemd.services =
      lib.mapAttrs' (
        name: job:
        lib.nameValuePair job.unit {
          serviceConfig = {
            StateDirectory = [ "health-job-${name}" ];
            ExecStartPre = lib.mkAfter [
              "${pkgs.python3}/bin/python3 ${../../../pkgs/health/job.py} baseline --record ${recordPath name} --baseline ${baselinePath name}"
            ];
            ExecStartPost = lib.mkAfter [
              "${pkgs.python3}/bin/python3 ${../../../pkgs/health/job.py} record --record ${recordPath name}"
            ];
          };
        }
      ) jobs
      // {
        flake-health-alert = lib.mkIf cfg.alert.enable {
          description = "Post the daily flake-health incident report to ntfy";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          onFailure = lib.optional notify.failureTemplate.enable "notify-fail@%n.service";
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "flake-health";
            ExecStart = "${package}/bin/flake-health-alert --state-dir /var/lib/flake-health";
          };
        };
      };
    systemd.timers.flake-health-alert = lib.mkIf cfg.alert.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.alert.dates;
        Persistent = true;
        RandomizedDelaySec = "10min";
      };
    };

    teq.nixos.health.checks =
      (lib.mapAttrs' (
        name: job:
        lib.nameValuePair "job.${name}" {
          command = [
            "${pkgs.python3}/bin/python3"
            "${../../../pkgs/health/job.py}"
            "check"
            "--record"
            (recordPath name)
            "--baseline"
            (baselinePath name)
            "--systemctl"
            "${pkgs.systemd}/bin/systemctl"
            "--journalctl"
            "${pkgs.systemd}/bin/journalctl"
            "--unit"
            job.unit
            "--max-age"
            (toString job.maxSuccessAge)
            "--max-runtime"
            (toString job.maxRuntime)
            "--boot-grace"
            (toString job.bootGrace)
            "--resume-grace"
            (toString job.resumeGrace)
            "--grace-limit"
            (toString job.graceLimit)
          ];
        }
      ) jobs)
      // lib.mapAttrs' (
        mount: disk:
        lib.nameValuePair
          (
            "disk."
            + (if mount == "/" then "root" else lib.replaceStrings [ "/" ] [ "_" ] (lib.removePrefix "/" mount))
          )
          {
            inherit (disk) enable;
            command = [
              "${pkgs.monitoring-plugins}/bin/check_disk"
              "-E"
              "-w"
              disk.warning
              "-c"
              disk.critical
              "-W"
              "10%"
              "-K"
              "5%"
              "-p"
              mount
            ];
          }
      ) cfg.disks
      //
        lib.mapAttrs'
          (
            name: kind:
            lib.nameValuePair name {
              command = [
                "${pkgs.python3}/bin/python3"
                "${../../../pkgs/health/check-system.py}"
                kind
                "${pkgs.systemd}/bin/systemctl"
                "${pkgs.systemd}/bin/timedatectl"
              ];
            }
          )
          {
            "systemd.failed" = "failed";
            "time.sync" = "clock";
            "system.reboot" = "reboot";
          }
      // lib.foldlAttrs (
        acc: name: url:
        acc
        // {
          "net.http.${name}".command = [
            "${pkgs.python3}/bin/python3"
            "${../../../pkgs/health/check-http.py}"
            "${pkgs.monitoring-plugins}/bin/check_http"
            url
          ];
        }
        // lib.optionalAttrs (lib.hasPrefix "https://" url) {
          "net.cert.${name}".command = [
            "${pkgs.python3}/bin/python3"
            "${../../../pkgs/health/check-http.py}"
            "${pkgs.monitoring-plugins}/bin/check_http"
            url
            "certificate"
          ];
        }
      ) { } cfg.endpoints;
  };
}
