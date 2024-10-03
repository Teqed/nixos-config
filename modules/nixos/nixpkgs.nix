{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
in {
  options.teq.nixos = {
    nixpkgs = lib.mkEnableOption "Teq's NixOS Nixpkgs configuration defaults.";
  };
  config = lib.mkIf cfg.nixpkgs {
    nixpkgs = {
      config = {
        # allowBroken = true;
        allowUnfree = true;
        # allowUnsupportedSystem = true;
      };
      # You can add overlays here
      overlays = [
        # Add overlays your own flake exports (from overlays and pkgs dir):
        # outputs.overlays.additions
        # outputs.overlays.modifications

        # You can also add overlays exported from other flakes:
        # neovim-nightly-overlay.overlays.default
        # inputs.nixpkgs-wayland.overlay # We only want to use these overlays in Wayland

        # Or define it inline, for example:
        # (final: prev: {
        #   hi = final.hello.overrideAttrs (oldAttrs: {
        #     patches = [ ./change-hello-to-hi.patch ];
        #   });
        # })
      ];
    };
  };
}
