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
    kernel = lib.mkOption {
      type = lib.types.enum [
        "latest"
        "zen"
        "cachyos"
      ];
      default = "latest";
      description = "Kernel package set.";
    };
  };
  config = lib.mkIf config.teq.nixos.enable {
    systemd.services.systemd-udev-settle.enable = mkDefault false;
    systemd.services.NetworkManager-wait-online.enable = mkDefault false;
    boot = {
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
      {
        latest = pkgs.linuxPackages_latest;
        zen = pkgs.linuxPackages_zen;
        cachyos = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
      }
      .${config.teq.nixos.kernel};
    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642;
    };
    services.irqbalance.enable = lib.mkDefault true;
  };
}
