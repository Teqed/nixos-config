{
  # Lower priority = checked first
  substituters = [
    "https://cache.nixos.org?priority=10" # Official nixpkgs
    "https://thoughtful.binarycache.shatteredsky.net?priority=20" # Local cache
    "https://teq.cachix.org?priority=60" # Personal cachix
    "https://nix-community.cachix.org?priority=80" # Community packages
    "https://attic.xuyh0120.win/lantian?priority=40" # CachyOS kernel
    "https://claude-code.cachix.org?priority=50" # Claude code
    "https://nixpkgs-unfree.cachix.org?priority=70" # Unfree packages
    "https://ghostty.cachix.org?priority=55" # Ghostty (tip builds)
  ];

  trustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "thoughtful.binarycache.shatteredsky.net:yPenzjz5AHspYSCnuLULxLVe/9h+d0FLqlnuBmbogz0="
    "teq.cachix.org-1:vzpACVksI6em8mYjeJbTWp9x+jQmZiReS7pNot65l+A="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
    "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
  ];
}
