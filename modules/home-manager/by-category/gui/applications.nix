{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      bibata-cursors
      papirus-icon-theme
      plex-desktop
      handbrake
      obsidian
      parsec-bin
      wl-clipboard
      wl-clipboard-x11
      kdePackages.wayland-protocols
      kdePackages.filelight
      moonlight-qt
      gg-jj
      prismlauncher
      qalculate-qt
      kdePackages.kalk
      krita
      haruna
      digikam
      kdePackages.yakuake
      kdePackages.kcharselect
      dolphin-emu
      teams-for-linux
      (callPackage ../../../../pkgs/by-name/cl/claude-desktop/package.nix { })
      (callPackage ../../../../pkgs/by-name/go/gooey-pi/package.nix { })
    ];
    services = {
      kdeconnect.enable = lib.mkDefault true;

      recoll = {
        enable = lib.mkDefault false;
        configDir = "${config.xdg.configHome}/recoll";
        settings = {
          nocjk = true;
          loglevel = 5;
          topdirs = [
            "~/_/Downloads"
            "~/_/Documents"
          ];

          "~/_/Downloads" = {
            "skippedNames+" = [ "*.iso" ];
          };

          "~/_/Repos" = {
            "skippedNames+" = [
              "node_modules"
              "target"
              "result"
            ];
          };
        };
      };
    };
  };
}
