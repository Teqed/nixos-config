# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  scripts = pkgs.callPackage ./scripts {};
  kando = pkgs.callPackage ./by-name/ka/kando/package.nix {};
}
