fromFlakes: let
  modulesPerFile = {
    nix-ld = import ./nix-ld.nix;
    boot = import ./boot.nix;
    impermanence = import ./impermanence.nix;
    programs = import ./programs.nix;
    services = import ./services.nix;
    networking = import ./networking.nix;
    desktop = import ./desktop;
    nixcfg = import ./nixcfg.nix;
    # nyx-cache = import ./nyx-cache.nix fromFlakes;
    # nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    media = import ./media.nix;
  };
  default = {...}: {
    imports = builtins.attrValues modulesPerFile;
  };
in
  modulesPerFile // {inherit default;}
