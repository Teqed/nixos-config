{
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager;
  inherit (lib) mkDefault mkForce;
in {
  options.teq.home-manager = {
    fonts = lib.mkEnableOption "Teq's Home-Manager Fonts configuration defaults.";
  };
  config = lib.mkIf cfg.fonts {
    fonts = {
      fontconfig.enable = mkForce true;

      fontconfig.defaultFonts = {
        serif = mkDefault [
          "Source Serif Pro"
          "Noto Serif"
          "Noto Serif CJK SC"
          "Noto Serif CJK TC"
          "Noto Serif CJK JP"
          "Noto Serif CJK KR"
          "Noto Color Emoji"
          "Noto Emoji"
        ];

        sansSerif = mkDefault [
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

        monospace = mkDefault [
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

        emoji = mkDefault ["Noto Color Emoji" "Noto Emoji"];
      };
    };
  };
}
