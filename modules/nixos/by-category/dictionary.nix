{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.gui.enable {
    environment.pathsToLink = [
      "/share/hunspell"
      "/share/myspell/dicts"
    ];
    environment.systemPackages = with pkgs; [
      ltex-ls
      nuspell
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      hunspell
      hunspellDicts.en_US
    ];
  };
}
