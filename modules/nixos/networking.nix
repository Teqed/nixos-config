{lib, ...}: {
  networking = {
    networkmanager.enable = lib.mkDefault true; # Enable networking
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault lib.mkDefault true; # Attempt to enable DHCP on all interfaces
    interfaces.enp1s0.useDHCP = lib.mkDefault true; # Attempt to enable DHCP on the first ethernet interface
    wireless.enable = lib.mkDefault true; # Enables wireless support via wpa_supplicant.
    wireless.userControlled.enable = lib.mkDefault true; # Allow normal users to control wpa_supplicant through wpa_gui or wpa_cli. This is useful for laptop users that switch networks a lot and don’t want to depend on a large package such as NetworkManager just to pick nearby access points. When using a declarative network specification you cannot persist any settings via wpa_gui or wpa_cli.
  };
}
