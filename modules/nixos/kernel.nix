{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.teq.nixos.kernel;
in {
  options.teq.nixos.kernel = {
    enable = lib.mkEnableOption "Teq's NixOS Kernel configuration defaults.";
    cachyos = lib.mkEnableOption "Enable CachyOS kernel.";
  };
  config = lib.mkIf cfg.enable {
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    boot.kernelPackages =
      if cfg.cachyos
      then pkgs.linuxPackages_cachyos # Use the CachyOS kernel
      else pkgs.linuxPackages; # Use the default kernel # linux-6.11 500MB
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642; # Required for some games
    };
    chaotic = lib.mkIf cfg.cachyos {
      scx = {
        enable = true; # Additional configurations for scheduler
        scheduler = "scx_rusty";
      };
    };
  };
}
