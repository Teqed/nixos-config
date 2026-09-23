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
    home.file.".curlrc".text = ''
      user-agent = "teq/1.0 (+https://shatteredsky.net; teqed@shatteredsky.net)"
    '';
  };
}
