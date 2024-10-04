# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
fromFlakes: let
  modulesPerFile = {
    fonts = import ./fonts.nix;
    nixcfg = import ./nixcfg.nix;
    locale = import ./locale.nix;
    packages = import ./packages.nix;
    programs = import ./programs.nix;
    paths = import ./paths.nix;
    theming = import ./theming.nix;
    # mime-apps = import ./mime-apps.nix;
    files = import ./files.nix;
  };
  default = {...}: {
    imports = builtins.attrValues modulesPerFile;
  };
in
  modulesPerFile // {inherit default;}
