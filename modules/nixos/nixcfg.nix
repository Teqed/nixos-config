{
  inputs,
  lib,
  config,
  outputs,
  ...
}:
with lib; let
  flakeInputs = filterAttrs (_: isType "flake") inputs;
  substituter_list = [
    "https://thoughtful.binarycache.shatteredsky.net"
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org/"
    "https://teq.cachix.org"
    "https://cache.iog.io"
    "https://digitallyinduced.cachix.org"
    "https://ghc-nix.cachix.org"
    "https://ic-hs-test.cachix.org"
    "https://kaleidogen.cachix.org"
    "https://static-haskell-nix.cachix.org"
    "https://tttool.cachix.org"
    "https://cache.garnix.io/"
    "https://nixcache.reflex-frp.org"
    "https://chaotic-nyx.cachix.org/"
    "https://yazi.cachix.org"
    "https://nixpkgs-wayland.cachix.org"
    "https://nixpkgs-unfree.cachix.org"
  ];
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
      };
      # You can add overlays here
      overlays = [
        # Add overlays your own flake exports (from overlays and pkgs dir):
        # outputs.overlays.additions
        outputs.overlays.modifications

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
        experimental-features = mkDefault ["nix-command" "flakes" "ca-derivations" "recursive-nix" "auto-allocate-uids"];
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
        substituters = substituter_list;
        trusted-substituters = substituter_list;
        trusted-users = mkForce ["root" "teq" "@wheel"];
        trusted-public-keys = [
          "thoughtful.binarycache.shatteredsky.net:yPenzjz5AHspYSCnuLULxLVe/9h+d0FLqlnuBmbogz0="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "teq.cachix.org-1:vzpACVksI6em8mYjeJbTWp9x+jQmZiReS7pNot65l+A="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "digitallyinduced.cachix.org-1:y+wQvrnxQ+PdEsCt91rmvv39qRCYzEgGQaldK26hCKE="
          "ghc-nix.cachix.org-1:ziC/I4BPqeA4VbtOFpFpu6D1t6ymFvRWke/lc2+qjcg="
          "ic-hs-test.cachix.org-1:8Ct2qPYnI4jZSyE+wJ0aR5laqaE2VRedzyX7JplSsHI="
          "kaleidogen.cachix.org-1:Ib2KIGCtrU/QFt1MRQdLpx5QMBv9++CrZsUfXle7m/Q="
          "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
          "tttool.cachix.org-1:e/5HpIa6ZqwatH07kmO7di1p9K+AMrgkNHl/OGUUMzU="
          "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        ];
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
