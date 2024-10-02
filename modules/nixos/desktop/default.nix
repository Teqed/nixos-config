{
  inputs,
  lib,
  config,
  pkgs,
  # nixpkgs-wayland,
  ...
}: let
  cfg = config.teq.nixos.desktop;
  hostname = config.networking.hostName;
  # walls_repo = builtins.fetchGit {
  #   url = "https://github.com/dharmx/walls";
  #   rev = "6bf4d733ebf2b484a37c17d742eb47e5139e6a14";
  # };
  # image_mountains = pkgs.fetchurl {
  #   url = "https://github.com/dharmx/walls/blob/6bf4d733ebf2b484a37c17d742eb47e5139e6a14/cold/a_mountain_with_clouds_in_the_sky.jpg";
  #   hash = "sha256-QGE8aXulkm7ergxbYrLTeLoLZaMCITutLM4a+s8x1pc=";
  # };
in {
  options.teq.nixos.desktop = {
    enable = lib.mkEnableOption "Teq's NixOS Desktop configuration defaults.";
  };
  imports = [
    ./bluetooth.nix
    ./fonts.nix
    ./steam.nix
    ./pipewire.nix
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
  config = lib.mkIf cfg.enable {
    teq.nixos.desktop.bluetooth = lib.mkDefault true;
    teq.nixos.desktop.fonts = lib.mkDefault true;
    teq.nixos.desktop.audio.enable = lib.mkDefault true; # Enable audio defaults.
    teq.nixos.desktop.steam.enable = lib.mkDefault true; # Enable Steam defaults.
    environment.systemPackages = [pkgs.bibata-cursors]; # Allows cursors to be used in the system, like the login screen
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
    };
    # nixpkgs.overlays = [nixpkgs-wayland.overlay]; # Automated, pre-built, (potentially) pre-release packages for Wayland (sway/wlroots) tools for NixOS.
    hardware.graphics.enable32Bit = true; # On 64-bit systems, whether to support Direct Rendering for 32-bit applications (such as Wine). This is currently only supported for the nvidia and ati_unfree drivers, as well as Mesa.
    hardware.graphics.extraPackages = with pkgs; [
      rocmPackages.clr.icd
      amdvlk # Modern AMD Graphics Core Next (GCN) GPUs are supported through either radv, which is part of mesa, or the amdvlk package. Adding the amdvlk package to hardware.opengl.extraPackages makes both drivers available for applications and lets them choose.
      rocm-opencl-icd # Modern AMD Graphics Core Next (GCN) GPUs are supported through the rocm-opencl-icd package.
      rocmPackages.rocm-runtime # OpenCL Image support is provided through the non-free rocm-runtime package.
    ];
    hardware.graphics.extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk # The 32-bit AMDVLK drivers can be used in addition to the Mesa RADV drivers.
    ];
    hardware.enableRedistributableFirmware = true; # Whether to enable firmware with a license allowing redistribution.
    hardware.enableAllFirmware = true; # Whether to enable all firmware regardless of license.
    chaotic.mesa-git.enable = true; # Use the Mesa graphics drivers from the Chaotic-AUR repository.
    systemd.tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}" # Most software has the HIP libraries hard-coded.
    ];
  };
}
