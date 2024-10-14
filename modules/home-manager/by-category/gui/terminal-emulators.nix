{
  # pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    foot = {
      enable = lib.mkDefault true;
      # settings = { };
    };
  };
}