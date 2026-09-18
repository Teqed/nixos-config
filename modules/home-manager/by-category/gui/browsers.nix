{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    programs = {
      chromium = {
        enable = true;
        package = pkgs.brave.override { vulkanSupport = true; };
        dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
        extensions = [
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }
          { id = "ejddcgojdblidajhngkogefpkknnebdh"; }
          { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; }
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; }
          { id = "enamippconapkdmgfgjchkhakpfinmaj"; }
          { id = "amefmmaoenlhckgaoppgnmhlcolehkho"; }
          { id = "lpnakhpaodhdkleejaehlapdhbgjbddp"; }

          { id = "dneaehbmnbhcippjikoajpoabadpodje"; }
          { id = "jmpmfcjnflbcoidlgapblgpgbilinlem"; }
          { id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp"; }

          { id = "kbmfpngjjgdllneeigpgjifpgocmfgmb"; }
          { id = "hlepfoohegkhhmjieoechaddaejaokhf"; }

          { id = "cheogdcgfjpolnpnjijnjccjljjclplg"; }
          { id = "dabpnahpcemkfbgfbmegmncjllieilai"; }
          { id = "oedncfcpfcmehalbpdnekgaaldefpaef"; }
          { id = "fpnmgdkabkmnadcjpehmlllkndpkmiak"; }
          { id = "cimiefiiaegbelhefglklhhakcgmhkai"; }
        ];
        commandLineArgs = [
          "--use-angle=vulkan"
          "--enable-features=${
            lib.concatStringsSep "," [
              "AcceleratedVideoDecodeLinuxGL"
              "AcceleratedVideoEncoder"
              "WaylandWindowDecorations"
              "Vulkan"
              "VulkanFromANGLE"
              "DefaultANGLEVulkan"
            ]
          }"
          "--disable-features=${
            lib.concatStringsSep "," [
              "OutdatedBuildDetector"
              "UseChromeOSDirectVideoDecoder"
              "WebRtcAllowInputVolumeAdjustment"
            ]
          }"
        ];
      };
      firefox = {
        enable = true;
        package = pkgs.firefox.override { cfg.speechSynthesisSupport = config.teq.home-manager.tts; };
        configPath = "${config.xdg.configHome}/mozilla/firefox";
        nativeMessagingHosts = [
          pkgs.fx-cast-bridge
        ];
        policies.Preferences."dom.webgpu.enabled" = {
          Value = true;
          Status = "default";
        };
      };
    };

    home.activation.migrateFirefoxProfile = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
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
