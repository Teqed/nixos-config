{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.teq.nixos.desktop;
in {
  options.teq.nixos.desktop = {
    programs = lib.mkEnableOption "Teq's NixOS Desktop Program configuration defaults.";
  };
  config = lib.mkIf cfg.programs {
    programs = {
      appimage = {
        enable = lib.mkDefault true;
        binfmt = lib.mkDefault true; # NixOS-specific option
        package = pkgs.appimage-run.override {
          extraPkgs = pkgs: [pkgs.ffmpeg pkgs.imagemagick];
        };
      };
      fuse = {
        userAllowOther = lib.mkDefault true; # Allow non-root users to specify the allow_other or allow_root mount options, see mount.fuse3(8). Might not be needed
        mountMax = lib.mkDefault 32000; # Set the maximum number of FUSE mounts allowed to non-root users. Integer between 0 and 32767, default 1000
      };
    };

    environment.systemPackages = with pkgs; [
      papirus-icon-theme # Allows icons to be used in the system, like the login screen
      (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '') # QEMU virtualization with UEFI firmware
    ];

    virt-manager.enable = lib.mkDefault true;
    virtualisation.waydroid.enable = true;
    # boot.binfmt.emulatedSystems = [
    #   "aarch64-linux" # ARM
    #   "riscv64-linux" # RISC-V
    #   "x86_64-windows" # Windows
    #   "x86_64-linux" # Linux
    # ];

    environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Use the Ozone Wayland support in several Electron apps

    environment.etc."brave/policies/managed/DisableBraveRewardsWalletAI.json".text = ''
      {
        "BraveRewardsDisabled": true,
        "BraveWalletDisabled": true,
        "BraveVPNDisabled": true,
        "BraveAIChatEnabled": false
      }
    '';
    environment.etc."vivaldi/policies/managed/defaultExtensions.json".text = ''
        {
        "ExtensionSettings": {
          "cjpalhdlnbpafiamejdnhcphjbkeiagm": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "ejddcgojdblidajhngkogefpkknnebdh": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "mnjggcdmjocbbbhaepdhchncahnbgone": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "eimadpbcbfnmbkopoojfekhnkhdbieeh": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "enamippconapkdmgfgjchkhakpfinmaj": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "amefmmaoenlhckgaoppgnmhlcolehkho": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "lpnakhpaodhdkleejaehlapdhbgjbddp": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "dneaehbmnbhcippjikoajpoabadpodje": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "jmpmfcjnflbcoidlgapblgpgbilinlem": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "pkehgijcmpdhfbdbbnkijodmdjhbjlgp": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "kbmfpngjjgdllneeigpgjifpgocmfgmb": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "hlepfoohegkhhmjieoechaddaejaokhf": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "cheogdcgfjpolnpnjijnjccjljjclplg": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "dabpnahpcemkfbgfbmegmncjllieilai": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "oedncfcpfcmehalbpdnekgaaldefpaef": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "fpnmgdkabkmnadcjpehmlllkndpkmiak": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          },
          "cimiefiiaegbelhefglklhhakcgmhkai": {
            "installation_mode": "normal_installed",
            "update_url":
               "https://clients2.google.com/service/update2/crx"
          }
        }
      }
    '';
  };
}
