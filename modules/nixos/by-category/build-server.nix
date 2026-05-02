{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.teq.nixos.buildServer;
in {
  options.teq.nixos.buildServer = {
    enable = lib.mkEnableOption "nightly flake update + build all hosts to warm the local binary cache";

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/teq/.local/user-dirs/Repos/nixos-config";
      description = "Local clone of the flake repo. Must have unattended SSH push access.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "teq";
      description = "User to run the update under. Must own repoPath.";
    };

    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["thoughtful" "bubblegum" "eris" "sedna"];
      description = "nixosConfigurations to build (aarch64 hosts excluded).";
    };

    dates = lib.mkOption {
      type = lib.types.str;
      default = "03:00";
      description = "Run before client autoUpgrade so the cache is warm when clients pull.";
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "15min";
    };

    pushRemotes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["origin" "tangled"];
      description = "Remotes to push the lockfile commit to. First is required, rest are best-effort.";
    };

    sshIdentity = lib.mkOption {
      type = lib.types.str;
      default = "/home/teq/.ssh/id_ed25519";
      description = "Path to key for git push.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.flake-update = {
      description = "Update flake.lock, build all hosts to warm cache, and push";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = with pkgs; [git nix openssh coreutils];
      serviceConfig = {
        Type = "oneshot";
        User = cfg.user;
        WorkingDirectory = cfg.repoPath;
        Environment = "GIT_SSH_COMMAND=ssh -i ${cfg.sshIdentity} -o IdentitiesOnly=yes";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Restart = "on-failure";
        RestartSec = "5min";
      };
      script = ''
        set -euo pipefail

        git fetch origin
        git checkout main
        git pull --ff-only origin main

        nix flake update --commit-lock-file

        # --out-link creates GC roots so closures stay alive for nix-serve to hand to clients.
        mkdir -p result-builds
        ${lib.concatMapStringsSep "\n" (h: ''
          echo "::: building ${h}"
          nix build .#nixosConfigurations.${h}.config.system.build.toplevel \
            --out-link result-builds/${h} -L
        '')
        cfg.hosts}

        # First push is required, rest are best-effort (mirrors that may be flaky).
        ${let
          first = lib.head cfg.pushRemotes;
          rest = lib.tail cfg.pushRemotes;
        in ''
          git push ${first} main
          ${lib.concatMapStringsSep "\n" (r: ''git push ${r} main || echo "WARN: push to ${r} failed (non-fatal)"'') rest}
        ''}
      '';
    };

    systemd.timers.flake-update = {
      description = "Nightly flake-update timer";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.dates;
        Persistent = true;
        RandomizedDelaySec = cfg.randomizedDelaySec;
      };
    };
  };
}
