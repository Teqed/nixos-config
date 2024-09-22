{
  pkgs,
  lib,
  ...
}: {
  fonts = {
    enableDefaultPackages = true; # Enable a basic set of fonts providing several styles and families and reasonable coverage of Unicode.
    packages = with pkgs; [
      source-sans-pro
      source-serif-pro
      ibm-plex
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
      font-awesome
      noto-fonts
      noto-fonts-extra
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-emoji
      noto-fonts-monochrome-emoji
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      jigmo
      dejavu_fonts
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
    fontconfig.defaultFonts = {
      serif = [
        "Source Serif Pro"
        "Noto Serif"
        "Noto Serif CJK SC"
        "Noto Serif CJK TC"
        "Noto Serif CJK JP"
        "Noto Serif CJK KR"
        "Noto Color Emoji"
        "Noto Emoji"
      ];
      sansSerif = [
        "Source Sans Pro"
        "Noto Sans"
        "Noto Sans CJK SC"
        "Noto Sans CJK TC"
        "Noto Sans CJK JP"
        "Noto Sans CJK KR"
        "Noto Sans CJK HK"
        "Noto Color Emoji"
        "Noto Emoji"
      ];
      monospace = [
        "JetBrains Mono"
        "FiraCode Nerd Font Mono"
        "Noto Sans Mono"
        "Noto Sans Mono CJK SC"
        "Noto Sans Mono CJK TC"
        "Noto Sans Mono CJK JP"
        "Noto Sans Mono CJK KR"
        "Noto Sans Mono CJK HK"
        "Noto Color Emoji"
        "Noto Emoji"
      ];
      emoji = ["Noto Color Emoji" "Noto Emoji"];
    };
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
        name = "Source Code Pro";
        package = pkgs.source-code-pro;
      }
    ];
    extraOptions = "--term xterm-256color";
    extraConfig = "font-size=12";
    hwRender = true; # Whether to use 3D hardware acceleration to render the console.
  };
}
