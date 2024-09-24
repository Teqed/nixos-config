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
  config = mkIf cfg.enable {
    home.keyboard.layout = "us";
    home.language.base = "${defaultLang}";
    home.language.ctype = "${defaultLang}";
    home.language.numeric = "${defaultLang}";
    home.language.time = "${defaultLang}";
    home.language.collate = "${defaultLang}";
    home.language.monetary = "${defaultLang}";
    home.language.messages = "${defaultLang}";
    home.language.paper = "${defaultLang}";
    home.language.name = "${defaultLang}";
    home.language.address = "${defaultLang}";
    home.language.telephone = "${defaultLang}";
    home.language.measurement = "${defaultLang}";
  };
}
