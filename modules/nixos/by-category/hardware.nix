{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.gui.enable {
    services = {
      printing.enable = lib.mkDefault true;
      hardware.openrgb = {
        enable = lib.mkDefault true;
        package = pkgs.openrgb-with-all-plugins;
      };
      keyd = {
        enable = lib.mkDefault true;
        keyboards.default.settings = {
          main = {
            capslock = lib.mkDefault "overload(capslock, esc)";
          };
        };
      };
      earlyoom.enable = lib.mkDefault true;
      hardware.bolt.enable = lib.mkDefault true;
    };
    hardware = {
      bluetooth.enable = lib.mkDefault true;

      bluetooth.powerOnBoot = lib.mkDefault true;
      logitech.wireless.enable = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      logiops
    ];
  };
}
