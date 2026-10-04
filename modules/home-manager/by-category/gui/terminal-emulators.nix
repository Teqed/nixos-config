{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = [
      (lib.hiPrio pkgs.ghostty)
    ];
  };
}
