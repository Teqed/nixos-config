fromFlakes: let
  modulesPerFile = {
    kernel = import ./kernel.nix;
    nix-ld = import ./nix-ld.nix;
    locale = import ./locale.nix;
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
