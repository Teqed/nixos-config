{
  # pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  config = lib.mkIf config.teq.nixos.enable {
    services = {
      tailscale.enable = true;
      samba = {
        enable = mkDefault true; # Samba, the SMB/CIFS protocol.
        openFirewall = mkDefault true;
        nsswins = mkDefault true; # nss_wins, allows applications to resolve WINS/NetBIOS names (a.k.a. Windows machine names) by transparently querying the winbindd daemon .
        nmbd.enable = mkDefault true; # nmbd, which replies to NetBIOS over IP name service requests. It also participates in the browsing protocols which make up the Windows “Network Neighborhood” view.
      };
      samba-wsdd = {
        enable = mkDefault true; # WSDD, a Web Services Dynamic Discovery host daemon. Enables (Samba) hosts, like your local NAS device, to be found by Web Service Discovery Clients like Windows .
        openFirewall = mkDefault true;
        discovery = mkDefault true; # Enable discovery operation mode.
      };
      openssh = {
        enable = mkDefault true;
        settings = {
          X11Forwarding = mkDefault true;
          PermitRootLogin = mkDefault "no"; # disable root login
          PasswordAuthentication = mkDefault false; # disable password login
          StreamLocalBindUnlink = mkDefault "yes"; # Automatically remove stale sockets
          GatewayPorts = mkDefault "clientspecified"; # Allow forwarding ports to everywhere
          AcceptEnv = mkDefault "WAYLAND_DISPLAY"; # Let WAYLAND_DISPLAY be forwarded
        };
        openFirewall = mkDefault true;
      };
    };
    programs = {
      mosh.enable = mkDefault true;
    };
    # environment.systemPackages = with pkgs; [
    # ];
    networking = {
      networkmanager.enable = lib.mkDefault true;
      useDHCP = lib.mkDefault true; # Attempt to enable DHCP on all interfaces
      wireless.enable = lib.mkDefault false; # Enables wireless support via wpa_supplicant.
      wireless.userControlled.enable = lib.mkDefault true; # Allow normal users to control wpa_supplicant through wpa_gui or wpa_cli.
      stevenblack = lib.mkIf config.teq.nixos.blocklist {
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
        checkReversePath = "loose";
        trustedInterfaces = [ "tailscale0" ];
        allowedUDPPorts = [ 9000 config.services.tailscale.port ];
        allowedTCPPorts = [ 9000 47984 47989 47990 48010 ];
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
          {
            from = 47998;
            to = 48000;
          } # Sunshine
        ];
      };
      hosts = {
        "10.0.0.12" = [ "dreamer.local" "pihole.shatteredsky.net" "cloud-aio.shatteredsky.net" "awx.shatteredsky.net" ];
      };
    };
  };
}
