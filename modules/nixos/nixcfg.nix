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
    system.autoUpgrade.enable = true;
    system.autoUpgrade.allowReboot = false;
    time = {
      timeZone = mkDefault "America/New_York";
    };
    i18n = {
      defaultLocale = mkDefault "${defaultLang}";
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
