{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf config.teq.home-manager.enable {
      programs = {
        micro = {
          enable = lib.mkDefault true;
        };
        vim.enable = lib.mkDefault true;
      };
    })
    (lib.mkIf config.teq.home-manager.dev {
      programs.helix = {
        enable = lib.mkDefault true;
        extraPackages = [ pkgs.marksman ];
      };
    })
  ];
}
