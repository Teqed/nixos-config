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
    gui_amd = import ./gui/amd.nix;
    gui_bluetooth = import ./gui/bluetooth.nix;
    gui_fonts = import ./gui/fonts.nix;
    gui_steam = import ./gui/steam.nix;
    gui_audio = import ./gui/audio.nix;
    gui_services = import ./gui/services.nix;
    gui_programs = import ./gui/programs.nix;
  };
  default = {...}: {
    imports = builtins.attrValues modulesPerFile;
  };
in
  modulesPerFile // {inherit default;}
