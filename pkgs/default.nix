pkgs: {
  scripts = pkgs.callPackage ./scripts { };
  kando = pkgs.callPackage ./by-name/ka/kando/package.nix { };
  claude-desktop = pkgs.callPackage ./by-name/cl/claude-desktop/package.nix { };
  gooey-pi = pkgs.callPackage ./by-name/go/gooey-pi/package.nix { };
}
