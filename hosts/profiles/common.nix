{
  nix-flatpak,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkForce;
  userinfo.users = ["teq"];
in {
  imports = [
    nix-flatpak.nixosModules.nix-flatpak
  ];
  config = {
    system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
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
      ++ lib.forEach userinfo.users (u: {
        "${u}" = {
          isNormalUser = mkDefault true;
          description = mkDefault u;
          extraGroups = mkDefault ["networkmanager" "wheel" "audio" "docker"];
        };
      })
    );
    home-manager.users.teq = {};
    # home-manager.users = lib.forEach userinfo.users (u: {
    #   "${u}" = {};
    # });

    home-manager.backupFileExtension = lib.mkDefault "hm-backup";
    home-manager.useGlobalPkgs = lib.mkDefault true;

    # teq.nixos.enable = true;
    teq.nixpkgs = true;
    # teq.nixos = {
    #   boot = lib.mkDefault true;
    #   locale = lib.mkDefault true;
    #   kernel.enable = lib.mkDefault true;
    #   kernel.cachyos = lib.mkDefault true;
    #   networking.enable = lib.mkDefault true;
    #   networking.blocking = lib.mkDefault true;
    #   nix-ld = lib.mkDefault true;
    #   programs = lib.mkDefault true;
    #   services = lib.mkDefault true;
    #   # desktop = lib.mkDefault true; # Optional for headless servers.
    #   nixcfg = lib.mkDefault true;
    # };
  };
}
