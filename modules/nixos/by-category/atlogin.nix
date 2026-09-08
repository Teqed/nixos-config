{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.teq.nixos.atlogin;
  package = pkgs.callPackage ../../../pkgs/by-name/at/atlogin/package.nix { src = inputs.atlogin; };
  stateDir = "/var/lib/atlogin";
  clientsDir = "${stateDir}/clients";
  bin = lib.getExe package;
  seed = pkgs.writeText "atlogin-config.json" (
    builtins.toJSON {
      addr = "127.0.0.1:${toString cfg.port}";
      issuer = "https://${cfg.domain}";
      client_name = cfg.clientName;
      secrets = { };
    }
  );
in
{
  options.teq.nixos.atlogin = {
    enable = lib.mkEnableOption "ATProto OIDC bridge behind Caddy";
    domain = lib.mkOption {
      type = lib.types.str;
      example = "atlogin.shatteredsky.net";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 9411;
    };
    clientName = lib.mkOption {
      type = lib.types.str;
      default = "Shattered Sky";
    };
    clients = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    secretGroup = lib.mkOption {
      type = lib.types.str;
      default = "atlogin";
    };
    clientSecretDir = lib.mkOption {
      type = lib.types.str;
      default = clientsDir;
      readOnly = true;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.atlogin = {
      isSystemUser = true;
      group = "atlogin";
      extraGroups = lib.optional (cfg.secretGroup != "atlogin") cfg.secretGroup;
    };
    users.groups.atlogin = { };

    systemd.services.atlogin = {
      description = "atlogin ATProto OIDC provider";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.jq
        pkgs.coreutils
      ];
      preStart = ''
        umask 077
        if [ ! -s ${stateDir}/config.json ]; then
          cp ${seed} ${stateDir}/config.json
          chmod 0600 ${stateDir}/config.json
          ${bin} -state-dir ${stateDir} -init
        fi
        mkdir -p ${clientsDir}
        for c in ${lib.escapeShellArgs cfg.clients}; do
          if [ "$(jq -r --arg c "$c" '.secrets[$c] // empty' ${stateDir}/config.json)" = "" ]; then
            ${bin} -state-dir ${stateDir} -new-client "$c" >/dev/null
          fi
          jq -r --arg c "$c" '.secrets[$c]' ${stateDir}/config.json > ${clientsDir}/"$c".tmp
          chgrp ${cfg.secretGroup} ${clientsDir}/"$c".tmp
          chmod 0640 ${clientsDir}/"$c".tmp
          mv ${clientsDir}/"$c".tmp ${clientsDir}/"$c"
        done
        chmod 0750 ${clientsDir}
        chgrp ${cfg.secretGroup} ${clientsDir}
      '';
      serviceConfig = {
        User = "atlogin";
        Group = "atlogin";
        StateDirectory = "atlogin";
        WorkingDirectory = stateDir;
        ExecStart = "${bin} -state-dir ${stateDir}";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
      };
    };

    services.caddy = {
      enable = true;
      virtualHosts.${cfg.domain}.extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port}
      '';
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
  };
}
