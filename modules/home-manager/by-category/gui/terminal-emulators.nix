{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = [
      (lib.hiPrio inputs.ghostty.packages.x86_64-linux.default) # Resolve terminfo conflict with ncurses
    ];
  };
}
