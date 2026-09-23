{
  pkgs,
  lib,
  config,
  ...
}:
let
  retroarchAutoconfigDir = "${config.xdg.configHome}/retroarch/autoconfig";
  retroarchAutoconfigStamp = "${config.xdg.stateHome}/retroarch/joypad-autoconfig-source";
in
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
    programs.retroarch = {
      enable = true;
      cores = {
        beetle-psx-hw.enable = true;
        dosbox-pure.enable = true;
        fceumm.enable = true;
        flycast.enable = true;
        gambatte.enable = true;
        genesis-plus-gx.enable = true;
        melonds.enable = true;
        mgba.enable = true;
        mupen64plus.enable = true;
        ppsspp.enable = true;
        snes9x.enable = true;
      };
      settings = {
        joypad_autoconfig_dir = retroarchAutoconfigDir;
      };
    };

    home.activation.seedRetroarchJoypadAutoconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ "$(cat ${retroarchAutoconfigStamp} 2>/dev/null)" != "${pkgs.retroarch-joypad-autoconfig}" ]; then
        $DRY_RUN_CMD mkdir -p ${retroarchAutoconfigDir}
        $DRY_RUN_CMD cp -rn --no-preserve=mode,ownership \
          ${pkgs.retroarch-joypad-autoconfig}/share/libretro/autoconfig/. ${retroarchAutoconfigDir}/
        $DRY_RUN_CMD chmod -R u+w ${retroarchAutoconfigDir}
        $DRY_RUN_CMD install -Dm644 \
          ${pkgs.writeText "retroarch-joypad-autoconfig-source" "${pkgs.retroarch-joypad-autoconfig}"} \
          ${retroarchAutoconfigStamp}
      fi
    '';

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
