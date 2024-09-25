{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
in {
  options.teq.nixos = {
    bluetooth = lib.mkEnableOption "Teq's NixOS Bluetooth configuration defaults.";
  };
  config = lib.mkIf cfg.bluetooth {
    hardware.bluetooth.enable = lib.mkDefault true; # enables support for Bluetooth
    # hardware.bluetooth.package = pkgs.bluez; # selects the Bluetooth package to use
    hardware.bluetooth.powerOnBoot = lib.mkDefault true; # powers up the default Bluetooth controller on boot
  };
}
