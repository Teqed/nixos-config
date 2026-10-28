{
  config,
  pkgs,
  lib,
  ...
}:
let
  chromium_policy = ../../../home-manager/sources/.config/chromium/policies/managed/defaultExtensions.json;
  brave_policy = ../../../home-manager/sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
in
{
  config = lib.mkIf config.teq.nixos.gui.enable {
    programs = {
      appimage = {
        enable = lib.mkDefault true;
        binfmt = lib.mkDefault true;
      };
      fuse = {
        userAllowOther = lib.mkDefault true;
        mountMax = lib.mkDefault 32000;
      };
      virt-manager.enable = lib.mkDefault false;
      mouse-actions.enable = lib.mkDefault true;
    };

    environment = {
      systemPackages = with pkgs; [
        solaar
        papirus-icon-theme
        bibata-cursors
        (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
          qemu-system-x86_64 \
            -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
            "$@"
        '')
      ];
      sessionVariables.NIXOS_OZONE_WL = "1";
      plasma6.excludePackages = with pkgs.kdePackages; [
        khelpcenter
      ];
      etc."chromium/policies/managed/defaultExtensions.json".source = chromium_policy;
      etc."brave/policies/managed/DisableBraveRewardsWalletAI.json".source = brave_policy;
    };

    virtualisation.waydroid.enable = lib.mkDefault false;
    boot.binfmt.emulatedSystems = [
      "aarch64-linux"
    ];

    hardware = {
      graphics.enable32Bit = true;
      enableRedistributableFirmware = true;
      enableAllFirmware = true;
    };

    services = {
      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        wayland.compositor = "kwin";

        settings = {
          Theme = {
            CursorTheme = "Bibata-Modern-Classic";
          };
        };
      };
      desktopManager.plasma6.enable = true;
      orca.enable = lib.mkForce false;
      speechd.enable = lib.mkForce false;
      colord.enable = lib.mkDefault true;
      flatpak = {
        enable = lib.mkDefault false;
        update.auto = {
          enable = lib.mkDefault true;
          onCalendar = lib.mkDefault "weekly";
        };
        overrides = {
          global = {
            Context.sockets = lib.mkDefault [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];
            Environment = {
              XCURSOR_PATH = lib.mkDefault "/run/host/user-share/icons:/run/host/share/icons";
              GTK_THEME = lib.mkDefault "Adwaita:dark";
            };
          };
          "com.visualstudio.code".Context = {
            filesystems = lib.mkDefault [
              "xdg-config/git:ro"
              "/run/current-system/sw/bin:ro"
            ];
            sockets = lib.mkDefault [
              "gpg-agent"
              "pcsc"
            ];
          };
          "org.onlyoffice.desktopeditors".Context.sockets = lib.mkDefault [ "x11" ];
        };
      };
      sunshine = {
        enable = lib.mkDefault true;
        openFirewall = lib.mkDefault true;
        capSysAdmin = lib.mkDefault true;
      };
      udev.extraRules = ''
        KERNEL=="uhid", TAG+="uaccess"
      '';
      xrdp = {
        enable = lib.mkDefault true;
        openFirewall = lib.mkDefault true;
      };
    };
  };
}
