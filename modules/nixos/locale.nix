{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    locale = lib.mkEnableOption "Teq's NixOS Locale configuration defaults.";
  };
  config = lib.mkIf cfg.locale {
    time = {
      timeZone = mkDefault "America/New_York";
    };
    i18n = {
      defaultLocale = mkDefault "${defaultLang}";
      extraLocaleSettings = {
        LC_ADDRESS = mkDefault "${defaultLang}";
        LC_IDENTIFICATION = mkDefault "${defaultLang}";
        LC_MEASUREMENT = mkDefault "${defaultLang}";
        LC_MONETARY = mkDefault "${defaultLang}";
        LC_NAME = mkDefault "${defaultLang}";
        LC_NUMERIC = mkDefault "${defaultLang}";
        LC_PAPER = mkDefault "${defaultLang}";
        LC_TELEPHONE = mkDefault "${defaultLang}";
        LC_TIME = mkDefault "${defaultLang}";
      };
    };
  };
}
