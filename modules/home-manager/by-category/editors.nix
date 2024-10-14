{
  pkgs,
  lib,
  config,
  ...
}: let
  # XDG_CONFIG_HOME = "${config.xdg.configHome}";
in {
  config = lib.mkIf config.teq.home-manager.enable {
    helix = {
      enable = lib.mkDefault true; # 400MB / 200MB (marksman 200MB / 20MB)
      extraPackages = [pkgs.marksman];
    };
    micro = {
      enable = lib.mkDefault true;
      # settings = { };
    };
    vim.enable = lib.mkDefault true; # 570MB / 75MB (vim-full 570MB / 90KB)
  };
}