{
  inputs,
  lib,
  config,
  pkgs,
  # nixpkgs-wayland,
  ...
}: let
  hostname = config.networking.hostName;
  inherit (lib) mkDefault;
  # walls_repo = builtins.fetchGit {
  #   url = "https://github.com/dharmx/walls";
  #   rev = "6bf4d733ebf2b484a37c17d742eb47e5139e6a14";
  # };
  # image_mountains = pkgs.fetchurl {
  #   url = "https://github.com/dharmx/walls/blob/6bf4d733ebf2b484a37c17d742eb47e5139e6a14/cold/a_mountain_with_clouds_in_the_sky.jpg";
  #   hash = "sha256-QGE8aXulkm7ergxbYrLTeLoLZaMCITutLM4a+s8x1pc=";
  # };
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
    # nixpkgs.overlays = [nixpkgs-wayland.overlay]; # Automated, pre-built, (potentially) pre-release packages for Wayland (sway/wlroots) tools for NixOS.
    environment.systemPackages = [pkgs.bibata-cursors]; # Allows cursors to be used in the system, like the login screen
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
                HeaderText = "${hostname}";
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
      colord.enable = mkDefault true; # color management daemon
      flatpak = {
        enable = mkDefault true;
        update.auto = {
          enable = mkDefault true;
          onCalendar = mkDefault "weekly"; # Default value
        };
        overrides = {
          global = {
            Context.sockets = mkDefault ["wayland" "!x11" "!fallback-x11"]; # Force Wayland by default
            Environment = {
              XCURSOR_PATH = mkDefault "/run/host/user-share/icons:/run/host/share/icons"; # Fix un-themed cursor in some Wayland apps
              GTK_THEME = mkDefault "Adwaita:dark"; # Force correct theme for some GTK apps
            };
          };
          "com.visualstudio.code".Context = {
            filesystems = mkDefault [
              "xdg-config/git:ro" # Expose user Git config
              "/run/current-system/sw/bin:ro" # Expose NixOS managed software
            ];
            sockets = mkDefault [
              "gpg-agent" # Expose GPG agent
              "pcsc" # Expose smart cards (i.e. YubiKey)
            ];
          };
          "org.onlyoffice.desktopeditors".Context.sockets = mkDefault ["x11"]; # No Wayland support
        };
      };
      sunshine = {
        enable = mkDefault true;
        openFirewall = mkDefault true;
        capSysAdmin = mkDefault true;
      };
      xrdp = {
        enable = mkDefault true;
        openFirewall = mkDefault true;
      };
    };
  };
}
