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
      firefox.enable = false; # 1.6GB / 300MB
    };
  };
}
