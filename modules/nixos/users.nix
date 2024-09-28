{
  lib,
  config,
  userinfo,
  ...
}: let
  cfg = config.teq.nixos;
  inherit (lib) mkDefault mkForce;
in {
  options.teq.nixos = {
    users = lib.mkEnableOption "Teq's NixOS Users configuration defaults.";
  };
  config = lib.mkIf cfg.users {
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
  };
}
