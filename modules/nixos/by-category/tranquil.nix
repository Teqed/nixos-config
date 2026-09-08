{
  config,
  options,
  lib,
  ...
}:
let
  cfg = config.teq.nixos.tranquil;
  envSecret = ../../../secrets/tranquil-env.age;
  hasEnv = (options ? age) && builtins.pathExists envSecret;
  backend = "[::1]:${toString config.services.tranquil-pds.settings.server.port}";
in
{
  options.teq.nixos.tranquil = {
    enable = lib.mkEnableOption "Tranquil PDS behind Caddy with on-demand TLS for handle subdomains";
    hostname = lib.mkOption {
      type = lib.types.str;
      example = "tran.quilling.dev";
    };
    handleDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ cfg.hostname ];
    };
    contactEmail = lib.mkOption {
      type = lib.types.str;
      default = "teqed@shatteredsky.net";
    };
    inviteOnly = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    mail = {
      fromAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      smarthost = lib.mkOption {
        type = lib.types.str;
        default = "smtp-relay.google.com";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 587;
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.optionalAttrs hasEnv {
        age.secrets.tranquil-env = {
          file = envSecret;
          mode = "0400";
        };
        services.tranquil-pds.environmentFiles = [ config.age.secrets.tranquil-env.path ];
      })
      {
        services.tranquil-pds = {
          enable = true;
          database.createLocally = true;
          settings.server = {
            inherit (cfg) hostname;
            user_handle_domains = cfg.handleDomains;
            invite_code_required = cfg.inviteOnly;
            disable_account_verification_gate = cfg.inviteOnly;
            enable_caddy_on_demand_tls = true;
            contact_email = cfg.contactEmail;
          };
          settings.email = lib.mkIf (cfg.mail.fromAddress != null) {
            from_address = cfg.mail.fromAddress;
            from_name = "Shattered Sky PDS";
            helo_name = cfg.hostname;
            smarthost = {
              host = cfg.mail.smarthost;
              inherit (cfg.mail) port;
              tls = "starttls";
            };
          };
        };

        systemd.services.tranquil-pds.restartTriggers = [
          config.environment.etc."tranquil-pds/config.toml".source
        ];

        services.caddy = {
          enable = true;
          globalConfig = ''
            on_demand_tls {
              ask http://${backend}/.well-known/caddy/ask
            }
          '';
          virtualHosts.${cfg.hostname}.extraConfig = ''
            reverse_proxy ${backend}
          '';
          virtualHosts."*.${cfg.hostname}".extraConfig = ''
            tls {
              on_demand
            }
            reverse_proxy ${backend}
          '';
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        nix.settings = {
          substituters = [ "https://tranquil.cachix.org" ];
          trusted-public-keys = [ "tranquil.cachix.org-1:PoO+mGL6a6LcJiPakMDHN4E218/ei/7v2sxeDtNkSRg=" ];
        };
      }
    ]
  );
}
