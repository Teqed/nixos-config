{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  options.teq.nixos = {
    cachyos = lib.mkEnableOption "Enable CachyOS kernel.";
  };
  config = lib.mkIf config.teq.nixos.enable {
    systemd.services.systemd-udev-settle.enable = mkDefault false;
    systemd.services.NetworkManager-wait-online.enable = mkDefault false;
    boot = {
      initrd = {
        systemd = {
          enable = mkDefault true;
        };
      };
      plymouth = {
        enable = mkDefault true;
      };
      kernelParams = [
      ];
    };
    fonts.packages = [ pkgs.noto-fonts-lgc-plus ];
    services.kmscon = {
      extraOptions = mkDefault "--term xterm-256color";
      config = mkDefault ''
        font-name=Noto Sans Mono
        font-size=10
      '';
    };
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    boot.kernelPackages =
      if config.teq.nixos.cachyos then
        pkgs.cachyosKernels.linuxPackages-cachyos-latest
      else
        pkgs.linuxPackages_latest;
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
    services.irqbalance.enable = lib.mkDefault true;
  };
}
