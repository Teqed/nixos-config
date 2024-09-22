{
  inputs,
  outputs,
  lib,
  config,
  ...
}: {
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    # Organized configuration files:
    ../common/boot.nix
    ../common/nix-ld.nix
    ../common/packages.nix
    ../common/services.nix
    ../common/users.nix
  ];
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      # You can add overlays here
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
  };
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # https://mynixos.com/nixpkgs/option/nix.settings.require-sigs
      # If enabled (the default), Nix will only download binaries from binary caches if they
      # are cryptographically signed with any of the keys listed in nix.settings.trusted-public-keys.
      # If disabled, signatures are neither required nor checked, so it’s strongly recommended that you
      # use only trustworthy caches and https to prevent man-in-the-middle attacks.
      # require-sigs = false; # binary cache go brrr
      experimental-features = "nix-command flakes ca-derivations recursive-nix repl-flake auto-allocate-uids"; # Enable flakes and new 'nix' command
      # flake-registry = ""; # Opinionated: disable global registry
      nix-path = config.nix.nixPath; # Workaround for https://github.com/NixOS/nix/issues/9574
      auto-optimise-store = true;
      # gc = {
      #   automatic = true;
      #   randomizedDelaySec = "10min";
      # };
      system-features = [
        "kvm"
        "big-parallel"
        "nixos-test"
        "benchmark"
      ];
      accept-flake-config = true; # Whether to accept nix configuration from a flake without prompting.
      allow-dirty = true; # Whether to allow dirty Git/Mercurial trees.
      allow-symlinked-store = true; # Nix will stop complaining if the store directory (typically /nix/store) contains symlink components.
      hashedMirrors = ["https://tarballs.nixos.org"];
      auto-allocate-uids = true; # Whether to select UIDs for builds automatically, instead of using the users in build-users-group.
      use-xdg-base-directories = true; # Nix will conform to the XDG Base Directory Specification for files in $HOME.
      # bash-prompt= ; # The bash prompt (PS1) in nix develop shells.
      substituters = [
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
      ];
      trusted-public-keys = [
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
      ];
    };
    # channel.enable = false; # Opinionated: disable channels
    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };
}
