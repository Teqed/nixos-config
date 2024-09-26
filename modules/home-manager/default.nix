# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
{
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager;
  # Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
in {
  options.teq.home-manager = {
    all = lib.mkEnableOption "Enable all of Teq's Home-Manager configuration defaults.";
  };
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default
    ./fonts.nix
    ./nixcfg.nix
    ./i18n_en_us_et.nix
    ./packages.nix
    ./programs.nix
    ./paths.nix
    ./theming.nix
    ./home-manager.nix
  ];
  config = {
    teq.home-manager = lib.mkIf cfg.all {
      fonts = lib.mkDefault true;
      nixcfg = lib.mkDefault true;
      locale = lib.mkDefault true;
      packages = lib.mkDefault true;
      programs = lib.mkDefault true;
      paths = lib.mkDefault true;
      theming = lib.mkDefault true;
      home-manager = lib.mkDefault true;
    };
  };
}
