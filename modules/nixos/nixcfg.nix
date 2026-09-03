{
  inputs,
  lib,
  config,
  options,
  outputs,
  ...
}:
with lib; let
  flakeInputs = filterAttrs (_: isType "flake") (removeAttrs inputs ["self"]);
  caches = import ../shared-caches.nix;
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    enable = lib.mkEnableOption "Teq's NixOS configuration defaults.";
    gui.enable = lib.mkEnableOption "Teq's NixOS GUI configuration defaults.";
    gui.amd = lib.mkEnableOption "Teq's NixOS AMD configuration defaults.";
    gui.steam = lib.mkEnableOption "Teq's NixOS Steam configuration defaults.";
    blocklist = lib.mkEnableOption "Enable host blocklist defaults.";
    samba = lib.mkEnableOption "Enable Samba/SMB interop (server, WS-Discovery, NetBIOS name resolution).";
  };
  config = lib.mkIf config.teq.nixos.enable ({
      system.stateVersion = lib.mkOverride 1100 "24.05"; # Weak fallback; hosts/profiles (e.g. the ISO) may mkDefault their own. https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      environment.enableAllTerminfo = mkDefault true;
      nixpkgs = {
        config = {
          # allowBroken = true;
          allowUnfree = true;
          # allowUnsupportedSystem = true;
          permittedInsecurePackages = [
            # vesktop's build-time pnpm; runtime closure is unaffected. Drop after
            # the next nixpkgs bump moves vesktop's pnpmDeps off 10.29.2.
            "pnpm-10.29.2"
          ];
        };
        # You can add overlays here
        overlays = [
          # Add overlays your own flake exports (from overlays and pkgs dir):
          # outputs.overlays.additions
          outputs.overlays.modifications
          inputs.claude-code.overlays.default
          inputs.prime-agent.overlays.default
          outputs.overlays.prime-agent-tweaks

          # You can also add overlays exported from other flakes:
          # neovim-nightly-overlay.overlays.default
          # inputs.nixpkgs-wayland.overlay # We only want to use these overlays in Wayland

          # Or define it inline, for example:
          # (final: prev: {
          #   hi = final.hello.overrideAttrs (oldAttrs: {
          #     patches = [ ./change-hello-to-hi.patch ];
          #   });
          # })
        ];
      };
      nix = {
        registry = mapAttrs (_: flake: {inherit flake;}) flakeInputs; # Opinionated: make flake registry and nix path match flake inputs
        nixPath = mkDefault (mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry); # Add inputs to the system's legacy channels Making legacy nix commands consistent

        # registry.nixpkgs.flake = inputs.nixpkgs;
        # nixPath = mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
        # channel.enable = false; # Opinionated: disable channels # Only available in NixOS
        gc = {
          automatic = mkDefault true;
          persistent = mkDefault true;
          dates = mkDefault "weekly"; # Not present in home-manager
          options = mkDefault "--delete-older-than 1w";
        };
        # Scheduled optimisation instead of per-write auto-optimise-store (faster builds)
        optimise = {
          automatic = mkDefault true;
          dates = mkDefault ["weekly"];
        };
        # Free up to 1GiB whenever there is less than 100MiB left.
        extraOptions = mkDefault (''
            min-free = ${toString (100 * 1024 * 1024)}
            max-free = ${toString (1024 * 1024 * 1024)}
          ''
          # Secret must contain a full line: access-tokens = github.com=<token>
          + lib.optionalString (options ? age) ''
            !include ${config.age.secrets."gh".path}
          '');
        settings = {
          # nix-path = mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";
          nix-path = mkDefault config.nix.nixPath; # Workaround for https://github.com/NixOS/nix/issues/9574
          bash-prompt-prefix = mkDefault "(nix:$name)\040";
          experimental-features = mkDefault [
            "nix-command"
            "flakes"
            "auto-allocate-uids" # Paired with auto-allocate-uids = true below
          ];
          accept-flake-config = mkDefault true; # Whether to accept nix configuration from a flake without prompting.
          allow-dirty = mkDefault true; # Whether to allow dirty Git/Mercurial trees.
          allow-symlinked-store = mkDefault true; # Nix will stop complaining if the store directory (typically /nix/store) contains symlink components.
          # hashedMirrors = mkDefault ["https://tarballs.nixos.org"];
          auto-allocate-uids = mkDefault true; # Whether to select UIDs for builds automatically, instead of using the users in build-users-group.
          use-xdg-base-directories = mkDefault true; # Nix will conform to the XDG Base Directory Specification for files in $HOME.
          system-features = mkDefault [
            "kvm" # use default instead?
            "big-parallel"
            "nixos-test"
            "benchmark"
          ];
          max-jobs = mkDefault "auto"; # default
          builders-use-substitutes = mkDefault true;
          substituters = caches.substituters;
          trusted-substituters = caches.substituters;
          trusted-users = mkForce [
            "root"
            "teq"
            "@wheel"
          ];
          trusted-public-keys = caches.trustedPublicKeys;
        };
      };
      # `enable` only when self has a clean revision — never clobber a host with local edits.
      system.autoUpgrade = {
        enable = mkDefault ((inputs.self.rev or "dirty") != "dirty");
        flake = mkDefault "git+https://tangled.org/@quilling.dev/nixos-config"; # Primary remote; GitHub is a best-effort mirror
        flags = mkDefault ["-L" "--refresh"];
        randomizedDelaySec = mkDefault "30min";
        dates = mkDefault "04:00";
        allowReboot = mkDefault false;
      };
      # Retry transient failures (NixOS/nixpkgs#274146); idle so post-suspend wakes don't stall.
      systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
        onFailure = lib.optional config.teq.nixos.notify.failureTemplate.enable "notify-fail@%n.service";
        startLimitIntervalSec = 3600;
        startLimitBurst = 6;
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = "60";
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
        };
      };

      time = {
        timeZone = mkDefault "America/New_York";
      };
      i18n = {
        defaultLocale = mkDefault "${defaultLang}";
        supportedLocales = mkDefault ["${defaultLang}/UTF-8" "C.UTF-8/UTF-8"]; # Saves ~200 MiB vs "all"; usb.nix overrides to "all" for installer
        extraLocaleSettings = {
          LC_ADDRESS = mkDefault "${defaultLang}";
          LC_IDENTIFICATION = mkDefault "${defaultLang}";
          LC_MEASUREMENT = mkDefault "${defaultLang}";
          LC_MONETARY = mkDefault "${defaultLang}";
          LC_NAME = mkDefault "${defaultLang}";
          LC_NUMERIC = mkDefault "${defaultLang}";
          LC_PAPER = mkDefault "${defaultLang}";
          LC_TELEPHONE = mkDefault "${defaultLang}";
          LC_TIME = mkDefault "${defaultLang}";
        };
      };
    }
    # Only when the agenix module is imported
    // lib.optionalAttrs (options ? age) {
      age.secrets."gh" = {
        file = ../../secrets/gh.age;
        mode = "0440";
        group = "wheel"; # Readable by nix clients (access-tokens is client-side)
      };
    });
}
