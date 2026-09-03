{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.enable {
    security = {
      sudo.enable = false;
      sudo-rs = {
        enable = true;
        wheelNeedsPassword = true;
        execWheelOnly = true;
        extraConfig = ''
          Defaults timestamp_timeout=480
        '';
      };
    };
  };
}
