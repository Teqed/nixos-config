{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  config = lib.mkIf config.teq.nixos.gui.enable {
    nixpkgs.config.joypixels.acceptLicense = mkDefault true;
    fonts = {
      fontconfig.enable = lib.mkForce true;
      fontconfig.defaultFonts = {
        serif = mkDefault [
          "IBM Plex Serif"
          "Noto Serif"
          "Noto Serif CJK SC"
          "Noto Serif CJK TC"
          "Noto Serif CJK JP"
          "Noto Serif CJK KR"
          "Noto Color Emoji"
          "Noto Emoji"
        ];
        sansSerif = mkDefault [
          "Inter"
          "Noto Sans"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK JP"
          "Noto Sans CJK KR"
          "Noto Sans CJK HK"
          "Noto Color Emoji"
          "Noto Emoji"
        ];
        monospace = mkDefault [
          "JetBrainsMono Nerd Font"
          "Noto Sans Mono"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK TC"
          "Noto Sans Mono CJK JP"
          "Noto Sans Mono CJK KR"
          "Noto Sans Mono CJK HK"
          "Noto Color Emoji"
          "Noto Emoji"
        ];
        emoji = mkDefault [
          "Noto Color Emoji"
          "Noto Emoji"
        ];
      };
      enableDefaultPackages = mkDefault true;

      packages = with pkgs; [
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono
        inter
        ibm-plex
        dejavu_fonts
        noto-fonts-lgc-plus
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-monochrome-emoji
        noto-fonts-color-emoji
        liberation_ttf
        winePackages.fonts
      ];

      fontDir.enable = mkDefault (!pkgs.stdenv.hostPlatform.isDarwin);
    };
  };
}
