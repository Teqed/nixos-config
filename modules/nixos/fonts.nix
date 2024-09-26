{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    fonts = lib.mkEnableOption "Teq's NixOS Font configuration defaults.";
  };
  imports = [
    ../home-manager/fonts.nix
  ];
  config = lib.mkIf cfg.fonts {
    nixpkgs.config.joypixels.acceptLicense = mkDefault true;

    fonts = {
      enableDefaultPackages = mkDefault true; # Enable a basic set of fonts providing several styles and families and reasonable coverage of Unicode.

      packages = mkDefault (with pkgs; [
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
          ]; # 208MB
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
        whatsapp-emoji-font
        powerline-symbols
        symbola
        material-icons
        weather-icons
        meslo-lgs-nf
      ]);

      fontDir.enable = mkDefault (!pkgs.stdenv.isDarwin);
    };

    services.kmscon = {
      enable = mkDefault true; # Use kmscon as the virtual console instead of gettys.
      fonts = mkDefault [
        {
          name = "Source Code Pro";
          package = pkgs.source-code-pro;
        }
      ];
      extraOptions = mkDefault "--term xterm-256color";
      extraConfig = mkDefault "font-size=12";
      # hwRender = mkDefault true; # Whether to use 3D hardware acceleration to render the console.
    };
  };
}
