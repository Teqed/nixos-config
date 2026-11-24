{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.teq.home-manager.cli {
      programs = {
        readline = {
          enable = lib.mkDefault true;
        };
      };
    })
    (lib.mkIf config.teq.home-manager.gui {
      home.packages = with pkgs; [
        notcurses
      ];
    })
  ];
}
