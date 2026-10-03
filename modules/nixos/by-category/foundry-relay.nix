{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.teq.nixos.foundryRelay;
  package = pkgs.callPackage ../../../pkgs/by-name/fo/foundryvtt-rest-api-relay/package.nix { };
  stateDir = "/var/lib/foundry-relay";
in
{
  options.teq.nixos.foundryRelay = {
    enable = lib.mkEnableOption "self-hosted Foundry REST API relay";
    port = lib.mkOption {
      type = lib.types.port;
      default = 3010;
    };
    openOnInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ config.services.tailscale.interfaceName ];
    };
    allowRegistration = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    maxHeadlessSessions = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 1;
    };
    chromium = lib.mkPackageOption pkgs "chromium" { };
    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.foundry-relay = {
      isSystemUser = true;
      group = "foundry-relay";
      home = stateDir;
    };
    users.groups.foundry-relay = { };

    systemd.services.foundry-relay = {
      description = "Foundry VTT REST API relay";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        APP_ENV = "production";
        PORT = toString cfg.port;
        DB_TYPE = "sqlite";
        DATA_DIR = stateDir;
        HOME = stateDir;
        ALLOW_HEADLESS = "true";
        MAX_HEADLESS_SESSIONS = toString cfg.maxHeadlessSessions;
        PUPPETEER_EXECUTABLE_PATH = lib.getExe cfg.chromium;
        CHROME_USER_DATA_DIR = "${stateDir}/chrome";
        CHROME_GPU_MODE = "swiftshader";
        DISABLE_REGISTRATION = lib.boolToString (!cfg.allowRegistration);
        PER_MINUTE_REQUEST_LIMIT = "0";
        MONTHLY_REQUEST_LIMIT = "0";
      }
      // cfg.environment;
      serviceConfig = {
        User = "foundry-relay";
        Group = "foundry-relay";
        StateDirectory = "foundry-relay";
        StateDirectoryMode = "0700";
        WorkingDirectory = stateDir;
        ExecStart = lib.getExe package;
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectClock = true;
        ProtectHostname = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
          "AF_NETLINK"
        ];
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        SystemCallArchitectures = "native";
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        UMask = "0077";
      };
    };

    networking.firewall.interfaces = lib.genAttrs cfg.openOnInterfaces (_: {
      allowedTCPPorts = [ cfg.port ];
    });
  };
}
