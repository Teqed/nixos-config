{
  lib,
  config,
  pkgs,
  ...
}:
let
  userinfo.users = [ "teq" ];
  userinfo.service_users = [ "media" ];
  inherit (lib) mkDefault mkForce;
in
{
  options = {
    userinfo = {
      users = lib.mkOption {
        type = with lib.types; listOf str;
        default = userinfo.users;
        description = "List of users to create.";
      };
      service_users = lib.mkOption {
        type = with lib.types; listOf str;
        default = userinfo.service_users;
        description = "List of service users to create.";
      };
    };
  };
  config = {
    teq.nixos.enable = true;
    programs.fish.enable = true;

    home-manager = {
      users.teq.teq.home-manager.enable = true;
      backupFileExtension = "backup-hm";
      useGlobalPkgs = lib.mkDefault true;
      useUserPackages = lib.mkDefault true;
    };
    users.users = lib.mkMerge (
      [
        {
          root.openssh.authorizedKeys.keys = mkForce [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
          ];
          teq = {
            isNormalUser = mkForce true;
            description = mkForce "Teq";
            shell = pkgs.fish;
            extraGroups = mkForce [
              "networkmanager"
              "wheel"
              "audio"
              "docker"
              "input"
              "dialout"
            ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
            ];
          };
        }
      ]
      ++ lib.forEach config.userinfo.users (u: {
        "${u}" = {
          isNormalUser = mkDefault true;
          description = mkDefault u;
          extraGroups = mkDefault [
            "networkmanager"
            "wheel"
            "audio"
            "docker"
          ];
        };
      })
      ++ lib.forEach config.userinfo.service_users (u: {
        "${u}" = {
          isSystemUser = mkDefault true;
          description = mkDefault u;
          group = mkDefault u;
          createHome = mkForce true;
          homeMode = mkForce "775";
          home = mkForce "/home/${u}";
        };
      })
    );
    users.groups = lib.mkMerge (
      lib.forEach config.userinfo.service_users (u: {
        "${u}" = {
          members = mkDefault [ u ];
        };
      })
    );
  };
}
