{
  # pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    programs = {
    foot = {
      enable = lib.mkDefault true;
      # settings = { };
    };
    };
  };
}