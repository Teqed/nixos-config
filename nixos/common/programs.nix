{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search, run: nix search wget
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
    ];
  environment.systemPackages = with pkgs; [
    # (import
    #   (builtins.fetchTarball {
    #     url = "https://github.com/NixOS/nixpkgs/archive/957d95fc8b9bf1eb60d43f8d2eba352b71bbf2be.tar.gz";
    #     sha256 = "sha256:0jkxg1absqsdd1qq4jy70ccx4hia3ix891a59as95wacnsirffsk";
    #   })
    #   { inherit system; }).wezterm
    papirus-icon-theme # Allows icons to be used in the system, like the login screen
    bibata-cursors # Allows cursors to be used in the system, like the login screen
  ];
  programs = {
    fzf = {
      fuzzyCompletion = true; # NixOS-specific option
      keybindings = true; # NixOS-specific option
    };
    mosh.enable = true;
    virt-manager.enable = true;
    java = {
      enable = true;
      binfmt = true; # NixOS-specific option
    };
    # appimage
    appimage = {
      enable = true;
      binfmt = true; # NixOS-specific option
      package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [pkgs.ffmpeg pkgs.imagemagick];
      };
    };
  };
}
