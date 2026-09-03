{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
  mosh-clean = pkgs.writeShellApplication {
    name = "mosh-clean";
    runtimeInputs = with pkgs; [
      coreutils
      procps
      gnugrep
      gnused
    ];
    text = builtins.readFile ../../../pkgs/scripts/src/mosh-clean.sh;
  };
  peer-sync = pkgs.writeShellApplication {
    name = "peer-sync";
    runtimeInputs = with pkgs; [
      coreutils
      rsync
      openssh
    ];
    text = builtins.readFile ../../../pkgs/scripts/src/peer-sync.sh;
  };
  seatDiscovery = ''
    seat="''${REMOTE_SEAT:-}"
    if [ -z "$seat" ] && [ -n "''${SSH_CONNECTION:-}" ]; then
      seat="''${SSH_CONNECTION%% *}"
    fi
    case "$seat" in *:*) seat="[$seat]" ;; esac # IPv6 literal
  '';
  inSshSession = ''[ -n "''${SSH_CONNECTION:-}''${SSH_TTY:-}''${SSH_CLIENT:-}" ]'';
  xdg-open-remote = pkgs.writeShellApplication {
    name = "xdg-open";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      socat
    ];
    text = ''
      ${seatDiscovery}
      if [ "''${REMOTE_OPEN:-1}" != 0 ] && [ -n "$seat" ] && ${inSshSession}; then
        case "''${1:-}" in
          http://* | https://*)
            url="$(printf '%s' "$1" | sed -E "s#^(https?://)(localhost|127\.0\.0\.1)(:|/|$)#\1$(uname -n)\3#")"
            if printf '%s\n' "$url" | socat -u -T5 - "TCP:$seat:46521,connect-timeout=2"; then
              exit 0
            fi
            ;;
        esac
      fi
      exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
    '';
  };
  pbcopy = pkgs.writeShellApplication {
    name = "pbcopy";
    runtimeInputs = with pkgs; [
      coreutils
      socat
      wl-clipboard
    ];
    text = ''
      ${seatDiscovery}
      if [ "''${REMOTE_OPEN:-1}" != 0 ] && [ -n "$seat" ] && ${inSshSession}; then
        if socat -u -T10 - "TCP:$seat:46522,connect-timeout=2"; then
          exit 0
        fi
      fi
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec wl-copy
      fi
      if [ -w /dev/tty ]; then
        printf '\033]52;c;%s\007' "$(base64 -w0)" > /dev/tty
        exit 0
      fi
      echo "pbcopy: no clipboard target (no seat, Wayland, or tty)" >&2
      exit 1
    '';
  };
  pbpaste = pkgs.writeShellApplication {
    name = "pbpaste";
    runtimeInputs = with pkgs; [
      coreutils
      socat
      wl-clipboard
    ];
    text = ''
      ${seatDiscovery}
      if [ "''${REMOTE_OPEN:-1}" != 0 ] && [ -n "$seat" ] && ${inSshSession}; then
        if socat -u -T10 "TCP:$seat:46523,connect-timeout=2" -; then
          exit 0
        fi
      fi
      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec wl-paste --no-newline
      fi
      echo "pbpaste: no clipboard source (no seat or Wayland)" >&2
      exit 1
    '';
  };
in
{
  config = lib.mkIf config.teq.nixos.enable {
    services = {
      tailscale.enable = true;
      openssh = {
        enable = mkDefault true;
        settings = {
          X11Forwarding = mkDefault true;
          PermitRootLogin = mkDefault "no"; # disable root login
          PasswordAuthentication = mkDefault false; # disable password login
          KbdInteractiveAuthentication = mkDefault false;
          AllowUsers = mkDefault [ "teq" ];
          StreamLocalBindUnlink = mkDefault "yes"; # Automatically remove stale sockets
          GatewayPorts = mkDefault "clientspecified"; # Allow forwarding ports to everywhere
          AcceptEnv = mkDefault [
            "WAYLAND_DISPLAY"
            "COLORTERM"
            "REMOTE_SEAT"
          ]; # waypipe, truecolor, seat identity
        };
        openFirewall = mkDefault true;
        hostKeys = mkDefault [
          {
            path = "/etc/ssh/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];
      };
      samba = {
        enable = mkDefault config.teq.nixos.samba;
        openFirewall = mkDefault true;
        nsswins = mkDefault config.teq.nixos.samba;
        nmbd.enable = mkDefault config.teq.nixos.samba;
      };
      samba-wsdd = {
        openFirewall = mkDefault true;
        discovery = mkDefault true;
      };
    };
    programs = {
      mosh.enable = mkDefault true;
      mosh.openFirewall = mkDefault false;
      ssh.extraConfig = ''
        SendEnv COLORTERM REMOTE_SEAT
      '';
    };
    environment.systemPackages =
      with pkgs;
      [
        waypipe # Wayland forwarding over SSH — useful on both ends
        cifs-utils # mount.cifs, CLI-usable
        mosh-clean # kill orphaned mosh-server sessions
        peer-sync # two-way newest-wins sync of selected dirs (FTL saves etc.)
        (lib.hiPrio xdg-open-remote) # remote-open shim over xdg-utils' xdg-open
        pbcopy # seat/local/OSC52 clipboard write
        pbpaste # seat/local clipboard read
      ]
      ++ lib.optionals config.teq.nixos.gui.enable [
        openfortivpn
        kdePackages.kio-fuse # to mount remote filesystems via FUSE
        kdePackages.kio-extras # extra protocols support (sftp, fish and more)
        kdePackages.qtsvg # support for svg icons
      ];
    # systemd.services.openfortivpn = {
    #   description = "OpenFortiVPN Service";
    #   after = [ "network.target" ];
    #   wants = [ "network-online.target" "systemd-networkd-wait-online.service" ];
    #   documentation = ["https://github.com/adrienverge/openfortivpn#readme"];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     Type = "notify";
    #     PrivateTmp = true;
    #     ExecStart = "${pkgs.openfortivpn}/bin/openfortivpn";
    #     Restart = "no";
    #     RestartSec = "30s";
    #     User = "root";
    #     Sockets = [ "openfortivpn.socket" ];
    #     StandardInput = "socket";
    #     StandardOutput = "journal";
    #     StandardError = "journal";
    #   };
    # };
    # systemd.sockets.openfortivpn = {
    #   description = "OpenFortiVPN Socket";
    #   socketConfig = {
    #     ListenFIFO = "/run/openfortivpn.stdin";
    #     Service = "openfortivpn.service";
    #     Accept = "false";
    #     RemoveOnStop = "yes";
    #     SocketMode = "0660";
    #   };
    # };
    networking = {
      # nftables.enable = true; # Attempt to get ipv6 forwarding for tailscale exit nodes working
      networkmanager.enable = lib.mkIf config.teq.nixos.gui.enable (lib.mkDefault true);
      useDHCP = lib.mkDefault true; # Attempt to enable DHCP on all interfaces
      wireless.enable = lib.mkDefault false; # Enables wireless support via wpa_supplicant.
      wireless.userControlled = lib.mkDefault true; # Allow normal users to control wpa_supplicant through wpa_gui or wpa_cli.
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
        allowedUDPPorts = [
          9000
          config.services.tailscale.port
          3000
        ];
        allowedTCPPorts = [
          9000
          3000
        ];
        allowedTCPPortRanges = lib.optionals config.teq.nixos.gui.enable [
          {
            from = 1714;
            to = 1764;
          } # KDE Connect
        ];
        allowedUDPPortRanges = lib.optionals config.teq.nixos.gui.enable [
          {
            from = 1714;
            to = 1764;
          } # KDE Connect
        ];
        extraCommands = lib.optionalString config.teq.nixos.samba "iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns";
      };
      hosts = {
        "10.0.0.12" = [
          "dreamer.local"
          "pihole.shatteredsky.net"
          "cloud-aio.shatteredsky.net"
          "awx.shatteredsky.net"
        ];
      };
    };
  };
}
