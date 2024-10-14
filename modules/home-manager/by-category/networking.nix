{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages = with pkgs; [
      curl # 55MB / 200KB (openssl)
      wget
      ### browsers:
      lynx
      w3m-nox
    ];
  };
}
