{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos.networking;
in {
  options.teq.nixos.networking = {
    enable = lib.mkEnableOption "Teq's NixOS Network configuration defaults.";
    blocking = lib.mkEnableOption "Enable host blocklist defaults.";
  };
  config.networking = lib.mkIf cfg.enable {
    networkmanager.enable = lib.mkDefault true; # Enable networking (!options.networking.wireless.enable)
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true; # Attempt to enable DHCP on all interfaces
    # interfaces.enp1s0.useDHCP = lib.mkDefault true; # Attempt to enable DHCP on the first ethernet interface # Not needed by default
    wireless.enable = lib.mkDefault false; # Enables wireless support via wpa_supplicant.
    wireless.userControlled.enable = lib.mkDefault true; # Allow normal users to control wpa_supplicant through wpa_gui or wpa_cli. This is useful for laptop users that switch networks a lot and don’t want to depend on a large package such as NetworkManager just to pick nearby access points. When using a declarative network specification you cannot persist any settings via wpa_gui or wpa_cli.
    stevenblack = lib.mkIf cfg.blocking {
      enable = true;
      block = [
        "fakenews"
        "gambling"
        "porn"
        # "social"
      ];
    };
    firewall = {
      enable = true;
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        } # KDE Connect
      ];
    };
  };
}
