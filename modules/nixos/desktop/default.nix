{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos.desktop;
in {
  options.teq.nixos.desktop = {
    enable = lib.mkEnableOption "Teq's NixOS Desktop configuration defaults.";
  };
  imports = [
    ./amd.nix
    ./bluetooth.nix
    ./fonts.nix
    ./steam.nix
    ./audio.nix
    ./services.nix
    ./programs.nix
  ];
  config = lib.mkIf cfg.enable {
    teq.nixos.desktop.bluetooth = lib.mkDefault true;
    teq.nixos.desktop.services = lib.mkDefault true;
    teq.nixos.desktop.programs = lib.mkDefault true;
    teq.nixos.desktop.fonts = lib.mkDefault true;
    teq.nixos.desktop.audio = lib.mkDefault true;
    teq.nixos.desktop.steam = lib.mkDefault false;
    teq.nixos.desktop.amd = lib.mkDefault false;
  };
}
