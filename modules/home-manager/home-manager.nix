{
  lib,
  config,
  inputs,
  outputs,
  userinfo,
  ...
}: let
  cfg = config.teq.home-manager;
in {
  options.teq.home-manager = {
    config = lib.mkEnableOption "Teq's NixOS Bluetooth configuration defaults.";
  };
  config = lib.mkIf cfg.bluetooth {
    home.stateVersion = lib.mkDefault "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home-manager.backupFileExtension = lib.mkDefault "hm-backup";
    home-manager.useGlobalPkgs = lib.mkDefault true;
    home-manager.extraSpecialArgs = lib.mkDefault {inherit inputs outputs userinfo;};
  };
}
