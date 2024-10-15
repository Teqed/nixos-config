{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.nixos.enable {
    # services = {
    # };
    # programs = {
    # };
    environment.pathsToLink = [
      "/share/hunspell"
      "/share/myspell/dicts"
    ];
    environment.systemPackages = with pkgs; [
      ltex-ls # LSP language server for LanguageTool
      diction # GNU style and diction utilities
      nuspell # C++ spell checking library
      aspell # Spell checker for many languages
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      hunspell # Spell checker of LibreOffice, OpenOffice.org, Firefox & Thunderbird, Chrome
      hunspellDicts.en_US
      # hunspellDictsChromium.en_US # Not usable as a package
    ];
  };
}
