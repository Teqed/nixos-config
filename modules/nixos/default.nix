fromFlakes: let
  modulesPerFile = {
    # nyx-cache = import ./nyx-cache.nix fromFlakes;
    # nyx-overlay = import ../common/nyx-overlay.nix fromFlakes;
    programs_development = import ./by-category/development.nix;
    programs_dictionary = import ./by-category/dictionary.nix;
    programs_fhs = import ./by-category/fhs.nix;
    programs_hardware = import ./by-category/hardware.nix;
    programs_media = import ./by-category/media.nix;
    programs_misc = import ./by-category/misc.nix;
    programs_networking = import ./by-category/networking.nix;
    programs_security = import ./by-category/security.nix;
    gui_amd = import ./by-category/gui/amd.nix;
    gui_audio = import ./by-category/gui/audio.nix;
    gui_fonts = import ./by-category/gui/fonts.nix;
    gui_programs = import ./by-category/gui/programs.nix;
    gui_steam = import ./by-category/gui/steam.nix;
    boot = import ./boot.nix;
    impermanence = import ./impermanence.nix;
    nixcfg = import ./nixcfg.nix;
  };
  default = {...}: {
    imports = builtins.attrValues modulesPerFile;
  };
in
  modulesPerFile // {inherit default;}
