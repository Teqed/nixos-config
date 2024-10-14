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
    networkmanager.enable = lib.mkDefault true;
    useDHCP = lib.mkDefault true; # Attempt to enable DHCP on all interfaces
    wireless.enable = lib.mkDefault false; # Enables wireless support via wpa_supplicant.
    wireless.userControlled.enable = lib.mkDefault true; # Allow normal users to control wpa_supplicant through wpa_gui or wpa_cli.
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
