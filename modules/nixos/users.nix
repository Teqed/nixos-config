{lib, ...}: let
  inherit (lib) mkDefault;
in {
  users.users.teq = {
    isNormalUser = mkDefault true;
    description = mkDefault "Teq";
    extraGroups = mkDefault ["networkmanager" "wheel" "audio" "docker"];
    openssh.authorizedKeys.keys = mkDefault [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
    ];
  };
}
