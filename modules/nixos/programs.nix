{
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkDefault;
in {
  nixpkgs.config.allowUnfree = mkDefault true;

  nixpkgs.config.allowUnfreePredicate = mkDefault (pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
    ]);

  environment.systemPackages = mkDefault (with pkgs; [
    papirus-icon-theme # Allows icons to be used in the system, like the login screen
    bibata-cursors # Allows cursors to be used in the system, like the login screen
  ]);

  programs = {
    fzf = {
      fuzzyCompletion = mkDefault true; # NixOS-specific option
      keybindings = mkDefault true; # NixOS-specific option
    };

    mosh.enable = mkDefault true;

    virt-manager.enable = mkDefault true;

    java = {
      enable = mkDefault true;
      binfmt = mkDefault true; # NixOS-specific option
    };

    appimage = {
      enable = mkDefault true;
      binfmt = mkDefault true; # NixOS-specific option
      package = mkDefault (pkgs.appimage-run.override {
        extraPkgs = pkgs: [pkgs.ffmpeg pkgs.imagemagick];
      });
    };
  };
}
