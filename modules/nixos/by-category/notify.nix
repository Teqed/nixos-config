{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.teq.nixos.notify;
in {
  options.teq.nixos.notify = {
    server.enable = lib.mkEnableOption "ntfy-sh server";

    server.port = lib.mkOption {
      type = lib.types.port;
      default = 2586;
      description = "Local port the ntfy daemon listens on.";
    };

    url = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.shatteredsky.net";
      description = "Public base URL of the ntfy server. Used by clients to publish.";
    };

    topic = lib.mkOption {
      type = lib.types.str;
      default = "alerts";
      description = "Default topic for system notifications.";
    };

    failureTemplate.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the notify-fail@.service template that systemd units can reference via OnFailure=notify-fail@%n.service.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.server.enable {
      services.ntfy-sh = {
        enable = true;
        settings = {
          base-url = cfg.url;
          listen-http = ":${toString cfg.server.port}";
          behind-proxy = true;
        };
      };
      networking.firewall.allowedTCPPorts = [cfg.server.port];
    })

    (lib.mkIf cfg.failureTemplate.enable {
      systemd.services."notify-fail@" = {
        description = "Notify ntfy on failure of %i";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "notify-fail" ''
            unit="$1"
            host=$(${pkgs.nettools}/bin/hostname)
            ${pkgs.curl}/bin/curl -fsS \
              -H "Title: $host: $unit failed" \
              -H "Priority: high" \
              -H "Tags: warning,$host" \
              -d "Check journalctl -u $unit on $host for details." \
              ${cfg.url}/${cfg.topic} >/dev/null
          '' + " %i";
        };
      };
    })
  ];
}
