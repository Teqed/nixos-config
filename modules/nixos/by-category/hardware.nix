{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.nixos.enable {
    services = {
      printing.enable = lib.mkDefault true; # Enable CUPS to print documents.
      hardware.openrgb = {
        enable = lib.mkDefault true;
        package = pkgs.openrgb-with-all-plugins;
      };
      keyd = {
        # A key remapping daemon for linux. https://github.com/rvaiya/keyd
        enable = lib.mkDefault true;
        keyboards.default.settings = {
          main = {
            # overloads the capslock key to function as both escape (when tapped) and capslock (when held)
            capslock = lib.mkDefault "overload(capslock, esc)";
          };
        };
      };
      earlyoom.enable = lib.mkDefault true; # RAM is a kind of hardware
    };
    # programs = {
    # };
    environment.systemPackages = with pkgs; [
      logiops # Unofficial userspace driver for HID++ Logitech devices
    ];
    hardware.bolt.enable = lib.mkDefault true; # Thunderbolt 3 device manager
    hardware.bluetooth.enable = lib.mkDefault true; # enables support for Bluetooth
    # hardware.bluetooth.package = pkgs.bluez; # selects the Bluetooth package to use
    hardware.bluetooth.powerOnBoot = lib.mkDefault true; # powers up the default Bluetooth controller on boot
    hardware.logitech.wireless.enable = lib.mkDefault true; # Linux devices manager for the Logitech Unifying Receiver
  };
}
