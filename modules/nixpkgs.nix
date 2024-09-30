{
  lib,
  config,
  ...
}: let
  cfg = config.teq;
in {
  options.teq = {
    nixpkgs = lib.mkEnableOption "Teq's NixOS Nixpkgs configuration defaults.";
  };
  config = lib.mkIf cfg.nixpkgs {
    nixpkgs = {
      config = {
        # allowBroken = true;
        allowUnfree = true;
        # allowUnsupportedSystem = true;
      };
    };
  };
}
