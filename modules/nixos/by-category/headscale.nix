{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.teq.nixos.headscale;
  hs = lib.getExe config.services.headscale.package;
in
{
  options.teq.nixos.headscale = {
    enable = lib.mkEnableOption "Headscale control server";
    domain = lib.mkOption {
      type = lib.types.str;
      example = "headscale.shatteredsky.net";
    };
    baseDomain = lib.mkOption {
      type = lib.types.str;
      default = "ts.shatteredsky.net";
    };
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "teq" ];
    };
    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = "teqed@shatteredsky.net";
    };
    policy = lib.mkOption {
      type = lib.types.attrs;
      default = {
        acls = [
          {
            action = "accept";
            src = [ "*" ];
            dst = [ "*:*" ];
          }
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.headscale = {
      enable = true;
      address = "127.0.0.1";
      port = 8080;
      settings = {
        server_url = "https://${cfg.domain}";
        metrics_listen_addr = "127.0.0.1:9090";
        prefixes = {
          v4 = "100.64.0.0/10";
          v6 = "fd7a:115c:a1e0::/48";
          allocation = "sequential";
        };
        dns = {
          magic_dns = true;
          base_domain = cfg.baseDomain;
          nameservers.global = [
            "https://dns.nextdns.io/73e713"
            "2a07:a8c0::73:e713"
            "2a07:a8c1::73:e713"
          ];
        };
        derp = {
          urls = [ "https://controlplane.tailscale.com/derpmap/default" ];
          auto_update_enabled = true;
          update_frequency = "24h";
        };
        database = {
          type = "sqlite";
          sqlite.write_ahead_log = true;
        };
        ephemeral_node_inactivity_timeout = "30m";
        disable_check_updates = true;
        log.level = "info";
        policy = {
          mode = "file";
          path = pkgs.writeText "headscale-policy.json" (builtins.toJSON cfg.policy);
        };
      };
    };

    systemd.services.headscale-users = {
      after = [ "headscale.service" ];
      requires = [ "headscale.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.jq ];
      serviceConfig = {
        Type = "oneshot";
        User = config.services.headscale.user;
        Group = config.services.headscale.group;
      };
      script = ''
        for i in $(seq 1 30); do
          ${hs} users list -o json >/dev/null 2>&1 && break
          sleep 1
        done
        existing=$(${hs} users list -o json | jq -r '.[].name')
        for u in ${lib.escapeShellArgs cfg.users}; do
          grep -qx "$u" <<<"$existing" || ${hs} users create "$u"
        done
      '';
    };

    services.caddy = {
      enable = true;
      email = cfg.acmeEmail;
      virtualHosts.${cfg.domain}.extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.headscale.port}
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    environment.systemPackages = [ config.services.headscale.package ];
  };
}
