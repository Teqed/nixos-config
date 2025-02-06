{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault mkForce;
in {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      inter
      ibm-plex
      dejavu_fonts # 10MB
      noto-fonts-lgc-plus # 11MB
      noto-fonts-cjk-sans # 62MB
      noto-fonts-cjk-serif # 54MB
      noto-fonts-monochrome-emoji # 2MB
      noto-fonts-color-emoji # 10MB
      liberation_ttf # 4MB
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
    fonts = {
      fontconfig.enable = mkForce true;
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
        emoji = mkDefault ["Noto Color Emoji" "Noto Emoji"];
      };
    };
  };
}
