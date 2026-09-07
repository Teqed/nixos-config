{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.teq.nixos.cachePull;
  host = config.networking.hostName;
in
{
  options.teq.nixos.cachePull = {
    enable = lib.mkEnableOption "pull this host's prebuilt system closure from the build server instead of evaluating locally";

    buildServer = lib.mkOption {
      type = lib.types.str;
      default = "teq@thoughtful";
      description = "ssh target whose forced command prints this host's toplevel store path.";
    };

    buildServerHostKey = lib.mkOption {
      type = lib.types.str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9vESx3ERRcW5yFFJBd+EEmyGluZGFLGBdq1Z4lyLt/";
      description = "Host public key of the build server, pinned system-wide since root has no user known_hosts.";
    };

    buildServerHostNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "thoughtful"
        "thoughtful.internal"
        "100.64.0.3"
      ];
      description = "Names the build server may be reached by; all get the pinned host key.";
    };

    identityFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/ssh/ssh_host_ed25519_key";
      description = "Private key authorized on the build server under buildServer.pullKeys. Defaults to the host key so nothing needs generating.";
    };

    operation = lib.mkOption {
      type = lib.types.enum [
        "switch"
        "boot"
      ];
      default = "switch";
      description = "boot only stages the generation for the next reboot.";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "04:00";
      description = "Run after the build server's flake-update so the closure exists.";
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "30min";
    };
  };

  config = lib.mkIf cfg.enable {
    teq.nixos.health.jobs.cache-pull.maxRuntime = 7200;
    teq.nixos.health.checks."net.ssh.build-server".command = [
      "${pkgs.monitoring-plugins}/bin/check_ssh"
      "-H"
      (lib.last (lib.splitString "@" cfg.buildServer))
      "-t"
      "5"
    ];
    system.autoUpgrade.enable = lib.mkForce false;

    programs.ssh.knownHosts.cache-pull-build-server = {
      hostNames = cfg.buildServerHostNames;
      publicKey = cfg.buildServerHostKey;
    };

    systemd.services.cache-pull = {
      description = "Fetch prebuilt system closure from build server and activate";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      onFailure = lib.optional config.teq.nixos.notify.failureTemplate.enable "notify-fail@%n.service";
      restartIfChanged = false;
      stopIfChanged = false;
      unitConfig.X-StopOnRemoval = false;
      path = with pkgs; [
        nix
        openssh
        coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
      };
      script = ''
        set -euo pipefail
        target=$(ssh -T -i ${cfg.identityFile} -o IdentitiesOnly=yes -o BatchMode=yes ${cfg.buildServer})
        case "$target" in
          /nix/store/*-nixos-system-${host}-*) ;;
          *)
            echo "refusing unexpected path: $target" >&2
            exit 1
            ;;
        esac
        if [ "$target" = "$(readlink -f /run/current-system)" ]; then
          echo "already running $target"
          exit 0
        fi
        nix build --no-link "$target"
        nix-env -p /nix/var/nix/profiles/system --set "$target"
        "$target/bin/switch-to-configuration" ${cfg.operation}
      '';
    };

    systemd.timers.cache-pull = {
      description = "Nightly cache-pull timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.dates;
        Persistent = true;
        RandomizedDelaySec = cfg.randomizedDelaySec;
      };
    };
  };
}
