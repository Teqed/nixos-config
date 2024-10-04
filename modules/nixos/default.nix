fromFlakes: let
  modulesPerFile = {
    kernel = import ./kernel.nix;
    nix-ld = import ./nix-ld.nix;
    locale = import ./locale.nix;
    boot = import ./boot.nix;
    programs = import ./programs.nix;
    services = import ./services.nix;
    networking = import ./networking.nix;
    desktop = import ./desktop;
    nixcfg = import ./nixcfg.nix;
    nixpkgs = import ./nixpkgs.nix;
    # nyx-cache = import ./nyx-cache.nix fromFlakes;
    # nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
  };
  default = {...}: {
    imports = builtins.attrValues modulesPerFile;
  };
in
  modulesPerFile // {inherit default;}
