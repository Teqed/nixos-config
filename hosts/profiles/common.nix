{
  lib,
  config,
  ...
}: let
  userinfo.users = ["teq"];
  userinfo.service_users = ["media"];
  inherit (lib) mkDefault mkForce;
in {
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
    home-manager.backupFileExtension = lib.mkDefault "hm-backup";
    home-manager.useGlobalPkgs = lib.mkDefault true;
    home-manager.useUserPackages = lib.mkDefault true;
    # TODO: For each user, create a home-manager configuration.
    # home-manager.users = lib.forEach userinfo.users (u: {
    #   "${u}" = {};
    # });
    home-manager.users.teq.teq.home-manager.enable = true;
    users.users = lib.mkMerge (
      [
        {
          root.openssh.authorizedKeys.keys = mkForce [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
          ];
          teq = {
            isNormalUser = mkForce true;
            description = mkForce "Teq";
            extraGroups = mkForce ["networkmanager" "wheel" "audio" "docker"];
            openssh.authorizedKeys.keys = mkForce [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
            ];
          };
        }
      ]
      ++ lib.forEach config.userinfo.users (u: {
        "${u}" = {
          isNormalUser = mkDefault true;
          description = mkDefault u;
          extraGroups = mkDefault ["networkmanager" "wheel" "audio" "docker"];
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
          name = mkDefault u;
          members = mkDefault [u];
        };
      })
    );
  };
}
