{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    programs = lib.mkEnableOption "Teq's NixOS Programs configuration defaults.";
  };
  config = lib.mkIf cfg.programs {
    # documentation.man.enable = false; # Whether to install manual pages. This also includes man outputs.
    documentation.man.generateCaches = false; # Whether to generate the manual page index caches. This allows searching for a page or keyword using utilities like apropos(1) and the -k option of man(1).
    documentation.doc.enable = false; # Whether to install documentation distributed in packages’ /share/doc. Usually plain text and/or HTML. This also includes “doc” outputs.
    environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
    system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion

    nixpkgs.config.allowUnfree = mkDefault true;

    nixpkgs.config.allowUnfreePredicate = mkDefault (pkg:
      builtins.elem (lib.getName pkg) [
        # Add additional package names here
      ]);

    environment.systemPackages = mkDefault (with pkgs; [
      nix-output-monitor # nix output monitor
      papirus-icon-theme # Allows icons to be used in the system, like the login screen
      bibata-cursors # Allows cursors to be used in the system, like the login screen
    ]);

    programs = {
      git.enable = true;

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
  };
}
