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
        configPath = "${config.xdg.configHome}/mozilla/firefox"; # 26.05+ XDG default; migration handled by home.activation.migrateFirefoxProfile below
        nativeMessagingHosts = [
          # pkgs.tridactyl
          pkgs.fx-cast-bridge
          # pkgs.ff2mpv
        ];
      };
    };

    # One-shot migration: ~/.mozilla/firefox → $XDG_CONFIG_HOME/mozilla/firefox.
    # Idempotent — no-op once the new directory exists. Native messaging hosts
    # and global extensions stay under ~/.mozilla and aren't moved by this option.
    # Both source and destination sit under existing impermanence persistence roots
    # (.mozilla and .config), so the mv is a same-volume rename on /persist.
    home.activation.migrateFirefoxProfile = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
      oldDir="$HOME/.mozilla/firefox"
      newDir="${config.xdg.configHome}/mozilla/firefox"
      if [ -d "$oldDir" ] && [ ! -d "$newDir" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$newDir")"
        $DRY_RUN_CMD mv "$oldDir" "$newDir"
      fi
    '';
  };
}
