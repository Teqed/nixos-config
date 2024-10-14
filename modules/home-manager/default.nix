# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
fromFlakes: let
  modulesPerFile = {
    nixcfg = import ./nixcfg.nix;
    mime-apps = import ./mime-apps.nix;
    files = import ./files.nix;
    programs = import ./programs.nix;
    programs_development = import ./by-category/development.nix;
    programs_editors = import ./by-category/editors.nix;
    programs_file-managers = import ./by-category/file-managers.nix;
    programs_libraries = import ./by-category/libraries.nix;
    programs_networking = import ./by-category/networking.nix;
    programs_shells = import ./by-category/shells.nix;
    programs_system = import ./by-category/system.nix;
    programs_tools = import ./by-category/tools.nix;
    programs_version-management = import ./by-category/version-management.nix;
    programs_gui_applications = import ./by-category/gui/applications.nix;
    programs_gui_browsers = import ./by-category/gui/browsers.nix;
    programs_gui_editors = import ./by-category/gui/editors.nix;
    programs_gui_fontconfig = import ./by-category/gui/fontconfig.nix;
    programs_gui_instant-messengers = import ./by-category/gui/instant-messengers.nix;
    programs_gui_terminal-emulators = import ./by-category/gui/terminal-emulators.nix;
    programs_gui_theming = import ./by-category/gui/theming.nix;
  };
  default = {...}: {
    imports = builtins.attrValues modulesPerFile;
  };
in
  modulesPerFile // {inherit default;}
