{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.enable {
    programs = {
    };
  };
}
