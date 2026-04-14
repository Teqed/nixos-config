{
  # Lower priority = checked first
  substituters = [
    "https://cache.nixos.org?priority=10"  # Official nixpkgs
    "https://thoughtful.binarycache.shatteredsky.net?priority=20"  # Local cache
    "https://nixpkgs-wayland.cachix.org?priority=30"  # Wayland packages
    "https://attic.xuyh0120.win/lantian?priority=40" # CachyOS kernel
    "https://yazi.cachix.org?priority=50"  # Yazi file manager
    "https://claude-code.cachix.org?priority=50"  # Claude code
    "https://devenv.cachix.org?priority=55"  # devenv
    "https://teq.cachix.org?priority=60"  # Personal cachix
    "https://nixpkgs-unfree.cachix.org?priority=70"  # Unfree packages
    "https://nix-community.cachix.org?priority=80"  # Community packages
    "https://cache.garnix.io?priority=90"  # Garnix CI
  ];

  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "thoughtful.binarycache.shatteredsky.net:yPenzjz5AHspYSCnuLULxLVe/9h+d0FLqlnuBmbogz0="
    "teq.cachix.org-1:vzpACVksI6em8mYjeJbTWp9x+jQmZiReS7pNot65l+A="
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" # CachyOS kernel
    "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
    "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g+"
  ];

  # Haskell/specialty caches - not actively used, kept for reference
  # Can be added back to substituters if working with Haskell projects
  unusedSubstituters = [
    "https://cache.iog.io"  # Cardano/IOHK Haskell
    "https://digitallyinduced.cachix.org"  # IHP framework
    "https://ghc-nix.cachix.org"  # GHC builds
    "https://ic-hs-test.cachix.org"  # Internet Computer
    "https://kaleidogen.cachix.org"  # Specific project
    "https://static-haskell-nix.cachix.org"  # Static Haskell
    "https://tttool.cachix.org"  # TipToi tool
    "https://nixcache.reflex-frp.org"  # Reflex FRP
  ];

  unusedTrustedPublicKeys = [
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "digitallyinduced.cachix.org-1:y+wQvrnxQ+PdEsCt91rmvv39qRCYzEgGQaldK26hCKE="
    "ghc-nix.cachix.org-1:ziC/I4BPqeA4VbtOFpFpu6D1t6ymFvRWke/lc2+qjcg="
    "ic-hs-test.cachix.org-1:8Ct2qPYnI4jZSyE+wJ0aR5laqaE2VRedzyX7JplSsHI="
    "kaleidogen.cachix.org-1:Ib2KIGCtrU/QFt1MRQdLpx5QMBv9++CrZsUfXle7m/Q="
    "static-haskell-nix.cachix.org-1:Q17HawmAwaM1/BfIxaEDKAxwTOyRVhPG5Ji9K3+FvUU="
    "tttool.cachix.org-1:e/5HpIa6ZqwatH07kmO7di1p9K+AMrgkNHl/OGUUMzU+"
    "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI="
  ];
}