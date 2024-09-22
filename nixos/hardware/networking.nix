{lib, ...}: {
  networking = {
    networkmanager.enable = true; # Enable networking
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # interfaces.enp1s0.useDHCP = lib.mkDefault true;
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  };
}
