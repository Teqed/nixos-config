{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  chromium_policy = ../../../home-manager/sources/.config/chromium/policies/managed/defaultExtensions.json;
  brave_policy = ../../../home-manager/sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
in {
  imports = [
    {
      nixpkgs = {
        overlays = [
          (final: prev: {
            sddm-sugar-candy = inputs.sddmSugarCandy4Nix.packages.${pkgs.stdenv.hostPlatform.system}.sddm-sugar-candy;
          })
        ];
      };
    }
  ];
  config = lib.mkIf config.teq.nixos.gui.enable {
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
      virt-manager.enable = lib.mkDefault true;
      mouse-actions.enable = lib.mkDefault true; # Enable mouse-actions udev rules; required to use mouse gestures as non-root
    };

    environment.systemPackages = with pkgs; [
      # inputs.wezterm-flake.packages.${pkgs.system}.default # Wezterm flake
      solaar # 600MB / 30MB (gtk+3 600MB)
      papirus-icon-theme # Allows icons to be used in the system, like the login screen
      bibata-cursors # Allows cursors to be used in the system, like the login screen
      (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
        qemu-system-x86_64 \
          -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
          "$@"
      '') # QEMU virtualization with UEFI firmware
      inputs.zen-browser.packages."${system}".default
    ];

    virtualisation.waydroid.enable = true;
    boot.binfmt.emulatedSystems = [
      "aarch64-linux" # ARM
      # "riscv64-linux" # RISC-V
      # "x86_64-windows" # Windows
      # "x86_64-linux" # Linux
    ];

    environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Use the Ozone Wayland support in several Electron apps

    environment.etc."chromium/policies/managed/defaultExtensions.json".source = chromium_policy;
    environment.etc."brave/policies/managed/DisableBraveRewardsWalletAI.json".source = brave_policy;

    # nixpkgs.overlays = [nixpkgs-wayland.overlay]; # Automated, pre-built, (potentially) pre-release packages for Wayland (sway/wlroots) tools for NixOS.
    hardware.graphics.enable32Bit = true; # On 64-bit systems, whether to support Direct Rendering for 32-bit applications (such as Wine). This is currently only supported for the nvidia and ati_unfree drivers, as well as Mesa.
    hardware.enableRedistributableFirmware = true; # Whether to enable firmware with a license allowing redistribution.
    hardware.enableAllFirmware = true; # Whether to enable all firmware regardless of license.

    services = {
      xserver = {
        enable = true; # You can disable the X11 windowing system if you're only using the Wayland session.
        xkb = {
          # Configure keymap in X11
          layout = "us";
          variant = "";
        };
        # libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).
      };
      # Enable the KDE Plasma Desktop Environment.
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        wayland.compositor = "kwin";
        theme = ''${ # <-- string interpolation and nix expression inside {}
            pkgs.sddm-sugar-candy.override {
              settings = {
                # Background = image_mountains;
                DimBackgroundImage = "0.0";
                ScaleImageCropped = true;
                ScreenWidth = "1920";
                ScreenHeight = "1080";
                FullBlur = false;
                PartialBlur = true;
                BlurRadius = "100";
                HaveFormBackground = false;
                FormPosition = "center";
                BackgroundImageHAlignment = "center";
                BackgroundImageVAlignment = "center";
                MainColor = "white";
                AccentColor = "#fb884f";
                BackgroundColor = "#444";
                OverrideLoginButtonTextColor = "";
                InterfaceShadowSize = "6";
                InterfaceShadowOpacity = "0.6";
                RoundCorners = "20";
                ScreenPadding = "0";
                # Font = "Noto Sans";
                FontSize = "";
                ForceRightToLeft = false;
                ForceLastUser = true;
                ForcePasswordFocus = true;
                ForceHideCompletePassword = true;
                ForceHideVirtualKeyboardButton = false;
                ForceHideSystemButtons = false;
                AllowEmptyPassword = false;
                AllowBadUsernames = false;
                Locale = "";
                HourFormat = "HH:mm";
                DateFormat = "dddd, d of MMMM";
                HeaderText = "${config.networking.hostName}";
                TranslatePlaceholderUsername = "";
                TranslatePlaceholderPassword = "";
                TranslateShowPassword = "";
                TranslateLogin = "";
                TranslateLoginFailedWarning = "";
                TranslateCapslockWarning = "";
                TranslateSession = "";
                TranslateSuspend = "";
                TranslateHibernate = "";
                TranslateReboot = "";
                TranslateShutdown = "";
                TranslateVirtualKeyboardButton = "";
              };
            }
          }'';
        package = lib.mkForce pkgs.libsForQt5.sddm;
        extraPackages = with pkgs;
          lib.mkForce [
            libsForQt5.qt5.qtgraphicaleffects
          ];
        settings = {
          Theme = {
            CursorTheme = "Bibata-Modern-Classic";
            # CursorSize = 29;
          };
        };
      };
      desktopManager.plasma6.enable = true;
      colord.enable = lib.mkDefault true; # color management daemon
      flatpak = {
        enable = lib.mkDefault true;
        update.auto = {
          enable = lib.mkDefault true;
          onCalendar = lib.mkDefault "weekly"; # Default value
        };
        overrides = {
          global = {
            Context.sockets = lib.mkDefault ["wayland" "!x11" "!fallback-x11"]; # Force Wayland by default
            Environment = {
              XCURSOR_PATH = lib.mkDefault "/run/host/user-share/icons:/run/host/share/icons"; # Fix un-themed cursor in some Wayland apps
              GTK_THEME = lib.mkDefault "Adwaita:dark"; # Force correct theme for some GTK apps
            };
          };
          "com.visualstudio.code".Context = {
            filesystems = lib.mkDefault [
              "xdg-config/git:ro" # Expose user Git config
              "/run/current-system/sw/bin:ro" # Expose NixOS managed software
            ];
            sockets = lib.mkDefault [
              "gpg-agent" # Expose GPG agent
              "pcsc" # Expose smart cards (i.e. YubiKey)
            ];
          };
          "org.onlyoffice.desktopeditors".Context.sockets = lib.mkDefault ["x11"]; # No Wayland support
        };
      };
      sunshine = {
        enable = lib.mkDefault true;
        openFirewall = lib.mkDefault true;
        capSysAdmin = lib.mkDefault true;
      };
      xrdp = {
        enable = lib.mkDefault true;
        openFirewall = lib.mkDefault true;
      };
    };
  };
}
