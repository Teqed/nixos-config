{lib, ...}: let
  defaultLang = "en_US.UTF-8";
  inherit (lib) mkDefault;
in {
  home.keyboard.layout = mkDefault "us";
  home.language = {
    base = mkDefault "${defaultLang}";
    ctype = mkDefault "${defaultLang}";
    numeric = mkDefault "${defaultLang}";
    time = mkDefault "${defaultLang}";
    collate = mkDefault "${defaultLang}";
    monetary = mkDefault "${defaultLang}";
    messages = mkDefault "${defaultLang}";
    paper = mkDefault "${defaultLang}";
    name = mkDefault "${defaultLang}";
    address = mkDefault "${defaultLang}";
    telephone = mkDefault "${defaultLang}";
    measurement = mkDefault "${defaultLang}";
  };
}
