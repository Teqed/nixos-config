{
  config,
  lib,
  ...
}: let
  cfg = config.homeManagerModules.locale_en_us_et;
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkEnableOption mkIf;
in {
  options.homeManagerModules.locale_en_us_et.enable = mkEnableOption "Enables localization for en_US.UTF-8.";
  home.keyboard = mkIf cfg.enable {
    layout = "us";
  };
  config.home.language = mkIf cfg.enable {
    base = "${defaultLang}";
    ctype = "${defaultLang}";
    numeric = "${defaultLang}";
    time = "${defaultLang}";
    collate = "${defaultLang}";
    monetary = "${defaultLang}";
    messages = "${defaultLang}";
    paper = "${defaultLang}";
    name = "${defaultLang}";
    address = "${defaultLang}";
    telephone = "${defaultLang}";
    measurement = "${defaultLang}";
  };
}
