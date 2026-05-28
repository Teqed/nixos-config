{
  inputs,
  lib,
  config,
  outputs,
  ...
}:
with lib; let
  flakeInputs = filterAttrs (_: isType "flake") inputs;
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
  };
  config = lib.mkIf config.teq.nixos.enable {
    system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    nixpkgs = {
      config = {
        # allowBroken = true;
        allowUnfree = true;
        # allowUnsupportedSystem = true;
        permittedInsecurePackages = [
          "openssl-1.1.1w"
          "nodejs-slim-20.20.2"
        ];
      };
      # You can add overlays here
      overlays = [
        # Add overlays your own flake exports (from overlays and pkgs dir):
        # outputs.overlays.additions
        outputs.overlays.modifications
        inputs.claude-code.overlays.default

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
    age.secrets."gh" = {
        file = ../secrets/gh.age;
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
      # Free up to 1GiB whenever there is less than 100MiB left.
      extraOptions = mkDefault ''
        min-free = ${toString (100 * 1024 * 1024)}
        max-free = ${toString (1024 * 1024 * 1024)}
      '';
      settings = {
        access-keys = config.age.secrets."gh".path;
        # nix-path = mkForce "nixpkgs=/etc/nix/inputs/nixpkgs";
        nix-path = mkDefault config.nix.nixPath; # Workaround for https://github.com/NixOS/nix/issues/9574
        auto-optimise-store = mkDefault true;
        bash-prompt-prefix = mkDefault "(nix:$name)\040";
        experimental-features = mkDefault [
          "nix-command"
          "flakes"
          "ca-derivations"
          "recursive-nix"
          "auto-allocate-uids"
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
        extra-trusted-substituters = caches.extraSubstituters;
        trusted-users = mkForce [
          "root"
          "teq"
          "@wheel"
        ];
        trusted-public-keys = caches.trustedPublicKeys;
        extra-trusted-public-keys = caches.extraTrustedPublicKeys;
      };
    };
    # `enable` only when self has a clean revision — never clobber a host with local edits.
    system.autoUpgrade = {
      enable = mkDefault ((inputs.self.rev or "dirty") != "dirty");
      flake = mkDefault "github:Teqed/nixos-config";
      flags = mkDefault ["-L" "--refresh"];
      randomizedDelaySec = mkDefault "30min";
      dates = mkDefault "04:00";
      allowReboot = mkDefault false;
    };
    # Retry transient failures (NixOS/nixpkgs#274146); idle so post-suspend wakes don't stall.
    systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
      onFailure = lib.optional config.teq.nixos.notify.failureTemplate.enable "notify-fail@%n.service";
      startLimitIntervalSec = 120;
      startLimitBurst = 6;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "20";
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
      };
    };

    time = {
      timeZone = mkDefault "America/New_York";
    };
    i18n = {
      defaultLocale = mkDefault "${defaultLang}";
      supportedLocales = mkDefault [ "${defaultLang}/UTF-8" "C.UTF-8/UTF-8" ]; # Saves ~200 MiB vs "all"; usb.nix overrides to "all" for installer
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
  };
}
