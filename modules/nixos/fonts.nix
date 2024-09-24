{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../home-manager/fonts.nix
  ];
  fonts = {
    enableDefaultPackages = true; # Enable a basic set of fonts providing several styles and families and reasonable coverage of Unicode.
    packages = with pkgs; [
      source-sans-pro
      source-serif-pro
      source-code-pro
      ibm-plex
      dejavu_fonts
      (nerdfonts.override {
        fonts = [
          "NerdFontsSymbolsOnly"
          "IBMPlexMono"
          "CascadiaCode"
          "CascadiaMono"
          "FiraCode"
          "FiraMono"
          "DroidSansMono"
          "LiberationMono"
          "DejaVuSansMono"
          "JetBrainsMono"
        ];
      })
      noto-fonts-lgc-plus
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-monochrome-emoji
      noto-fonts-color-emoji
      liberation_ttf
      mplus-outline-fonts.githubRelease
      jigmo
      font-awesome
      twemoji-color-font
      joypixels
      whatsapp-emoji-linux
      powerline-symbols
      symbola
      material-icons
      weather-icons
      meslo-lgs-nf-unstable
    ];
    fontDir.enable = lib.mkIf (!pkgs.stdenv.isDarwin) true;
  };
  services.kmscon = {
    # https://wiki.archlinux.org/title/KMSCON
    # Use kmscon as the virtual console instead of gettys.
    # kmscon is a kms/dri-based userspace virtual terminal implementation.
    # It supports a richer feature set than the standard linux console VT,
    # including full unicode support, and when the video card supports drm should be much faster.
    enable = true;
    fonts = [
      {
        name = "JetBrains Mono";
        package = pkgs.nerdfonts.override {
          fonts = [
            "JetBrainsMono"
          ];
        };
      }
    ];
    extraOptions = "--term xterm-256color";
    extraConfig = "font-size=12";
    hwRender = true; # Whether to use 3D hardware acceleration to render the console.
  };
}
