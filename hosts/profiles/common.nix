{
  lib,
  config,
  ...
}: let
  userinfo.users = ["teq"];
  inherit (lib) mkDefault mkForce;
in {
  options = {
    userinfo = {
      users = lib.mkOption {
        type = with lib.types; listOf str;
        default = userinfo.users;
        description = "List of users to create.";
      };
    };
  };
  config = {
    teq.nixos = {
      # amd = lib.mkDefault true;
      boot = lib.mkDefault true;
      locale = lib.mkDefault true;
      nix-ld = lib.mkDefault true;
      nixcfg = lib.mkDefault true;
      programs = lib.mkDefault true;
      services = lib.mkDefault true;
      kernel.enable = lib.mkDefault true;
      kernel.cachyos = lib.mkDefault true;
      networking.enable = lib.mkDefault true;
      networking.blocking = lib.mkDefault true;
      # desktop = lib.mkDefault true; # Optional for headless servers.
    };
    networking.networkmanager.enable = mkDefault true;
    system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home-manager.backupFileExtension = lib.mkDefault "hm-backup";
    home-manager.useGlobalPkgs = lib.mkDefault true;
    home-manager.useUserPackages = lib.mkDefault true;
    # TODO: For each user, create a home-manager configuration.
    # home-manager.users = lib.forEach userinfo.users (u: {
    #   "${u}" = {};
    # });
    home-manager.users.teq = {
      home.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      teq.home-manager = {
        enable = true;
        theming = true; # plasma-manager
      };
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
    );
  };
}
