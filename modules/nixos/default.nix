{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  # Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
in {
  options.teq.nixos = {
    enable = lib.mkEnableOption "Enable all of Teq's NixOS configuration defaults.";
  };
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    # Organized configuration files:
    ./fonts.nix
    ./kernel.nix
    ./nix-ld.nix
    ./i18n_en_us_et.nix
    ./boot.nix
    ./programs.nix
    ./services.nix
    ./users.nix
    ./networking.nix
    ./impermanence.nix
    ./bluetooth.nix
    ./desktop
    ./nixcfg.nix
  ];
  config = lib.mkIf cfg.enable {
    home-manager.backupFileExtension = lib.mkDefault "hm-backup";
    home-manager.useGlobalPkgs = lib.mkDefault true;
    teq.nixos = {
      bluetooth = lib.mkDefault true;
      boot = lib.mkDefault true;
      fonts = lib.mkDefault true;
      locale = lib.mkDefault true;
      kernel.enable = lib.mkDefault true;
      kernel.cachyos = lib.mkDefault true;
      networking.enable = lib.mkDefault true;
      networking.blocking = lib.mkDefault true;
      nix-ld = lib.mkDefault true;
      programs = lib.mkDefault true;
      services = lib.mkDefault true;
      users = lib.mkDefault true;
      # impermanence = lib.mkDefault false; # Requires a BTRFS partition labeled "nixos".
      # desktop = lib.mkDefault true; # Optional for headless servers.
      nixcfg = lib.mkDefault true;
    };
  };
}
