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
    ./fonts.nix
    ./nixcfg.nix
    ./i18n_en_us_et.nix
  ];
  config = {
    teq.home-manager = lib.mkIf cfg.all {
      fonts = lib.mkDefault true;
      nixcfg = lib.mkDefault true;
      locale = lib.mkDefault true;
    };
  };
}
