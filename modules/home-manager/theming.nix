{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.teq.home-manager;
in {
  options.teq.home-manager = {
    theming = lib.mkEnableOption "Teq's NixOS Theming configuration defaults.";
  };
  config = lib.mkIf cfg.theming {
    home = {
      pointerCursor = {
        name = lib.mkDefault "Bibata-Modern-Classic";
        package = lib.mkDefault pkgs.bibata-cursors;
        gtk.enable = lib.mkDefault true;
        x11.enable = lib.mkDefault true;
        x11.defaultCursor = lib.mkDefault "Bibata-Modern-Classic";
      };
    };
    gtk = {
      enable = lib.mkDefault true;
      cursorTheme.name = lib.mkDefault "Bibata-Modern-Classic";
      cursorTheme.size = lib.mkDefault 24; # Default 16
      # font = "Noto Sans,  10"; null or (submodule)
      # iconTheme = "Papirus-Dark"; # null or (submodule)
    };
  };
}
