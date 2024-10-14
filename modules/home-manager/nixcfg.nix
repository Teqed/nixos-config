{
  # inputs,
  lib,
  config,
  osConfig,
  ...
}:
with lib; let
  # flakeInputs = filterAttrs (_: isType "flake") inputs;
  substituter_list = [
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
    "https://rossabaker.cachix.org/"
    "https://typelevel.cachix.org/"
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
  options.teq.home-manager = {
    enable = lib.mkEnableOption "Enable Teq's Home-Manager configuration defaults.";
    gui = lib.mkEnableOption "Enable GUI configuration.";
  };
  config = lib.mkIf config.teq.home-manager.enable {
    home.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.extraOutputsToInstall = ["info" "man" "share" "icons" "doc"];
    home.keyboard.layout = mkDefault "us";
    home.language = {
      base = mkDefault "${defaultLang}";
      ctype = mkDefault "${defaultLang}";
      numeric = mkDefault "${defaultLang}";
      time = mkDefault "${defaultLang}";
      collate = mkDefault "${defaultLang}";
      monetary = mkDefault "${defaultLang}";
      messages = mkDefault "${defaultLang}";
      paper = mkDefault "${defaultLang}";
      name = mkDefault "${defaultLang}";
      address = mkDefault "${defaultLang}";
      telephone = mkDefault "${defaultLang}";
      measurement = mkDefault "${defaultLang}";
    };
    nixpkgs = lib.mkIf (!osConfig.home-manager.useGlobalPkgs) {
      config = {
        allowUnfree = true;
      };
    };
    nix = {
      registry = osConfig.nix.registry;
      nixPath = osConfig.nix.nixPath;

      # channel.enable = false; # Opinionated: disable channels # Only available in NixOS
      gc = {
        automatic = mkDefault true;
        persistent = mkDefault true;
        # dates = mkDefault "weekly"; # Not present in home-manager
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
        experimental-features = mkDefault ["nix-command" "flakes" "ca-derivations" "recursive-nix" "repl-flake" "auto-allocate-uids"];
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
        substituters = mkDefault substituter_list;
        trusted-substituters = mkDefault substituter_list;
        trusted-users = mkForce ["root" "teq" "@wheel"];
        trusted-public-keys = mkDefault [
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
          "rossabaker.cachix.org-1:KK/CQTeAGEurCUBy3nDl9PdR+xX+xtWQ0C/GpNN6kuw="
          "typelevel.cachix.org-1:UnD9fMAIpeWfeil1V/xWUZa2g758ZHk8DvGCd/keAkg="
          "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
          "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
          "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
        ];
      };
    };
  };
}
