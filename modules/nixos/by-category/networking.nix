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
    case "$seat" in *:*) seat="[$seat]" ;; esac
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
          PermitRootLogin = mkDefault "no";
          PasswordAuthentication = mkDefault false;
          KbdInteractiveAuthentication = mkDefault false;
          AllowUsers = [ "teq" ];
          StreamLocalBindUnlink = mkDefault "yes";
          GatewayPorts = mkDefault "clientspecified";
          AcceptEnv = mkDefault [
            "WAYLAND_DISPLAY"
            "COLORTERM"
            "REMOTE_SEAT"
          ];
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
        waypipe
        cifs-utils
        mosh-clean
        peer-sync
        (lib.hiPrio xdg-open-remote)
        pbcopy
        pbpaste
      ]
      ++ lib.optionals config.teq.nixos.gui.enable [
        openfortivpn
        kdePackages.kio-fuse
        kdePackages.kio-extras
        kdePackages.qtsvg
      ];

    networking = {
      networkmanager.enable = lib.mkIf config.teq.nixos.gui.enable (lib.mkDefault true);
      useDHCP = lib.mkDefault true;
      wireless.enable = lib.mkDefault false;
      wireless.userControlled = lib.mkDefault true;
      stevenblack = lib.mkIf config.teq.nixos.blocklist {
        enable = true;
        block = [
          "fakenews"
          "gambling"
          "porn"
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
          }
        ];
        allowedUDPPortRanges = lib.optionals config.teq.nixos.gui.enable [
          {
            from = 1714;
            to = 1764;
          }
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
