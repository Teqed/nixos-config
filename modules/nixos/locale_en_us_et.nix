{
  config,
  lib,
  ...
}: let
  cfg = config.nixosModules.locale_en_us_et;
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkEnableOption mkIf;
in {
  options.nixosModules.locale_en_us_et.enable = mkEnableOption "Enables localization for en_US.UTF-8.";
  # time.timeZone = "America/New_York"; # Set your time zone.
  config.time = mkIf cfg.enable {
    timeZone = "America/New_York";
  };
  config.i18n = mkIf cfg.enable {
    defaultLocale = "${defaultLang}"; # Select internationalisation properties.
    extraLocaleSettings = {
      LC_ADDRESS = "${defaultLang}";
      LC_IDENTIFICATION = "${defaultLang}";
      LC_MEASUREMENT = "${defaultLang}";
      LC_MONETARY = "${defaultLang}";
      LC_NAME = "${defaultLang}";
      LC_NUMERIC = "${defaultLang}";
      LC_PAPER = "${defaultLang}";
      LC_TELEPHONE = "${defaultLang}";
      LC_TIME = "${defaultLang}";
    };
  };
}
