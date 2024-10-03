{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    services = lib.mkEnableOption "Teq's NixOS Services configuration defaults.";
  };
  config = lib.mkIf cfg.services {
    security.sudo = {
      enable = mkDefault true;
      package = pkgs.sudo.override {
        withInsults = true;
      };
      extraConfig = mkDefault ''
        Defaults lecture = never
      '';
    };
    services = {
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
      printing.enable = mkDefault true; # Enable CUPS to print documents.
      hardware.bolt.enable = mkDefault true; # Thunderbolt 3 device manager
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
      spice-vdagentd.enable = mkDefault true;
      earlyoom.enable = mkDefault true;
      hardware.openrgb = {
        enable = mkDefault true;
        package = pkgs.openrgb-with-all-plugins;
      };
      keyd = {
        # A key remapping daemon for linux. https://github.com/rvaiya/keyd
        enable = mkDefault true;
        keyboards.default.settings = {
          main = {
            # overloads the capslock key to function as both escape (when tapped) and capslock (when held)
            capslock = mkDefault "overload(capslock, esc)";
          };
        };
      };
    };
  };
}
