{...}: {
  hardware.bluetooth.enable = true; # enables support for Bluetooth
  # hardware.bluetooth.package = pkgs.bluez; # selects the Bluetooth package to use
  hardware.bluetooth.powerOnBoot = true; # powers up the default Bluetooth controller on boot
}
