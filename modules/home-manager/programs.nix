{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager.programs;
in {
  options.teq.home-manager.programs = {
    enable = lib.mkEnableOption "Teq's Home-Manager Programs configuration defaults.";
  };
  imports = [
    ./by-category/shells/programs.nix
  ];
  config = lib.mkIf cfg.enable {
    systemd.user.startServices = lib.mkDefault "sd-switch"; # Nicely reload system units when changing configs
    services = {
      kdeconnect.enable = lib.mkDefault true; # 1GB / 23MB
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
      # remmina.enable = true; # 900MB / 15MB (freerdp 700MB, spice-gtk 600MB)
    };
    programs = {
      chromium = {
        enable = true;
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
      vscode = {
        enable = lib.mkDefault true; # 1.44GB / 400MB (mesa 800MB)
        package = lib.mkDefault pkgs.vscodium-fhs;
        # enableUpdateCheck = lib.mkDefault false;
        # enableExtensionUpdateCheck = lib.mkDefault false;
        # userSettings = {
        #   "window.dialogStyle" = "custom";
        #   "window.customTitleBarVisibility" = "auto";
        #   "window.titleBarStyle" = "custom";
        #   "nix.enableLanguageServer" = true;
        #   "nix.serverPath" = "nixd";
        # };
        # extensions = with pkgs; [vscode-extension-jnoortheen-nix-ide];
      };
      # thunderbird.enable = true; # profiles needs to be set
      firefox.enable = false; # 1.6GB / 300MB
    };
  };
}
