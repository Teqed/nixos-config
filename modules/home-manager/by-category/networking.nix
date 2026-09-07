{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages = with pkgs; [
      curl
      wget
      lynx
      w3m-nox
      reader
    ];
  };
}
