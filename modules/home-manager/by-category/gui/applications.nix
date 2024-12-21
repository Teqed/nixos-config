{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      bibata-cursors # 160MB
      papirus-icon-theme # 200MB / 130MB
      ### emulators:
      mgba # 800MB / 10MB (ffmpeg)
      ### video:
      plex-media-player # 1.7GB / 300MB
      handbrake # 1.5GB / 64MB (ffmpeg 1.3GB / 35MB)
      ### misc:
      obsidian # 1.8GB / 20MB
      parsec-bin # Parsec Remote Desktop client
      # lan-mouse_git # 900MB / 10MB (libadwaita 900MB)
      ### tools - wayland
      wl-clipboard
      wl-clipboard-x11 # Wrapper to use wl-clipboard as a drop-in replacement for X11 clipboard tools
      kdePackages.wayland-protocols
      # kde:
      kdePackages.filelight # Disk usage analyzer
    ];
    services = {
      ### kde:
      kdeconnect.enable = lib.mkDefault true; # 1GB / 23MB
      ### search:
      recoll = {
        enable = lib.mkDefault true;
        configDir = "${config.xdg.configHome}/recoll";
        settings = {
          nocjk = true;
          loglevel = 5;
          topdirs = ["~/_/Downloads" "~/_/Documents" "~/_/Repos"];

          "~/_/Downloads" = {
            "skippedNames+" = ["*.iso"];
          };

          "~/_/Repos" = {
            "skippedNames+" = ["node_modules" "target" "result"];
          };
        };
      };
    };
  };
}
