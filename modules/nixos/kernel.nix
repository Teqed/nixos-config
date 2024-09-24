{
  config,
  lib,
  pkgs,
  types,
  ...
}: let
  cfg = config.nixosModules.kernel;
in {
  options.nixosModules.kernel = with types; enum ["default" "cachyos"];
  #   mkIfElse = p: yes: no: mkMerge [
  #   (mkIf p yes)
  #   (mkIf (!p) no)
  # ];
  config =
    if
      cfg.kernel
      == "cachyos"
    then {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      boot = {
        kernelPackages = pkgs.linuxPackages_cachyos; # Use the CachyOS kernel from Chaotic
        # This is for OBS Virtual Cam Support
        # kernelModules = [ "v4l2loopback" ];
        # extraModulePackages = [ config.kernelPackages.v4l2loopback ];
        kernel.sysctl = {"vm.max_map_count" = 2147483642;}; # Required for some games
      };
      chaotic.scx.enable = true;
      chaotic.scx.scheduler = "scx_rusty";
    }
    else {
      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      boot = {
        # kernelPackages = pkgs.linuxPackages;
        kernel.sysctl = {"vm.max_map_count" = 2147483642;};
      };
    };
}
