{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = [
      (pkgs.hiPrio inputs.ghostty.packages.x86_64-linux.default)  # hiPrio to resolve terminfo conflict with ncurses
    ];
  };
}
