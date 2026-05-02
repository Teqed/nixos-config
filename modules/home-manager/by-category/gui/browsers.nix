{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    programs = {
      chromium = {
        enable = true; # 2GB / 600 MB
        package = pkgs.brave;
        dictionaries = [pkgs.hunspellDictsChromium.en_US];
        extensions = [
          {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # ublock-origin
          {id = "ejddcgojdblidajhngkogefpkknnebdh";} # autoplaystopper
          {id = "mnjggcdmjocbbbhaepdhchncahnbgone";} # sponsorblock-for-youtube
          {id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";} # dark reader
          {id = "enamippconapkdmgfgjchkhakpfinmaj";} # DeArrow
          {id = "amefmmaoenlhckgaoppgnmhlcolehkho";} # github-vscode-icons-updated
          {id = "lpnakhpaodhdkleejaehlapdhbgjbddp";} # Hide Files on GitHub
          # {id = "fihnjjcciajhdojfnbdddfaoknhalnja";} # I don't care about cookies
          {id = "dneaehbmnbhcippjikoajpoabadpodje";} # old reddit redirect
          {id = "jmpmfcjnflbcoidlgapblgpgbilinlem";} # PixelBlock
          {id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";} # Privacy Badger
          # {id = "einpaelgookohagofgnnkcfjbkkgepnp";} # Random User-Agent (Switcher)
          {id = "kbmfpngjjgdllneeigpgjifpgocmfgmb";} # Reddit Enhancement Suite
          {id = "hlepfoohegkhhmjieoechaddaejaokhf";} # Refined GitHub
          # {id = "oiigbmnaadbkfbmpbfijlflahbdbdgdf";} # ScriptSafe
          {id = "cheogdcgfjpolnpnjijnjccjljjclplg";} # Showdown Randbats Tooltip
          {id = "dabpnahpcemkfbgfbmegmncjllieilai";} # Showdex
          {id = "oedncfcpfcmehalbpdnekgaaldefpaef";} # Substitoot
          {id = "fpnmgdkabkmnadcjpehmlllkndpkmiak";} # Wayback Machine
          {id = "cimiefiiaegbelhefglklhhakcgmhkai";} # Plasma Integration
        ];
        commandLineArgs = [
          "--disable-features=WebRtcAllowInputVolumeAdjustment"
        ];
      };
      firefox = {
        enable = true;
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        nativeMessagingHosts = [
          # pkgs.tridactyl
          pkgs.fx-cast-bridge
          # pkgs.ff2mpv
        ];
      };
    };

    # Bandaged XDG migration. HM-managed config files (profiles.ini etc.) live at the
    # XDG path. Firefox itself still reads from ~/.mozilla/firefox (Mozilla bug 2005167:
    # NMH has no XDG path yet, so ~/.mozilla/native-messaging-hosts/ keeps `.mozilla`
    # alive, which trips LegacyHomeExists), so we point that at the XDG dir via symlink.
    # Drop this once Mozilla bug 2005167 lands.
    home.activation.migrateFirefoxProfile = lib.hm.dag.entryBefore ["writeBoundary"] ''
      oldDir="$HOME/.mozilla/firefox"
      newDir="${config.xdg.configHome}/mozilla/firefox"
      if [ -d "$oldDir" ] && [ ! -L "$oldDir" ] && [ ! -e "$newDir" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$newDir")"
        $DRY_RUN_CMD mv "$oldDir" "$newDir"
      fi
      if [ -e "$newDir" ] && [ ! -e "$oldDir" ]; then
        $DRY_RUN_CMD ln -s "$newDir" "$oldDir"
      fi
    '';
  };
}
