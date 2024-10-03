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
      boot = lib.mkDefault true;
      locale = lib.mkDefault true;
      kernel.enable = lib.mkDefault true;
      kernel.cachyos = lib.mkDefault true;
      networking.enable = lib.mkDefault true;
      networking.blocking = lib.mkDefault true;
      nix-ld = lib.mkDefault true;
      programs = lib.mkDefault true;
      services = lib.mkDefault true;
      # desktop = lib.mkDefault true; # Optional for headless servers.
      # amd = lib.mkDefault true;
      nixcfg = lib.mkDefault true;
      nixpkgs = lib.mkDefault true;
    };
    networking.networkmanager.enable = mkDefault true;
    system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home-manager.backupFileExtension = "hm-backup";
    home-manager.useGlobalPkgs = lib.mkDefault true;
    home-manager.users.teq = {home.stateVersion = "24.05";}; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    # home-manager.users = lib.forEach userinfo.users (u: {
    #   "${u}" = {};
    # });
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
