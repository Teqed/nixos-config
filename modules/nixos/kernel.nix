{
  config,
  lib,
  pkgs,
  ...
}: let
  kernel_selected = config.teq.kernel.type or "default"; # Default option
in {
  options.teq.kernel.type = lib.mkOption {
    type = lib.types.str;
    default = "default";
    description = "Select the kernel to use: 'default' or 'cachyos'.";
  };

  config = {
    # Set the host platform
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    # Configure boot settings based on the selected kernel
    boot.kernelPackages =
      if kernel_selected == "cachyos"
      then pkgs.linuxPackages_cachyos # Use the CachyOS kernel
      else pkgs.linuxPackages; # Use the default kernel

    boot.kernel.sysctl = {
      "vm.max_map_count" = 2147483642; # Required for some games
    };

    # Additional configurations for CachyOS
    chaotic.scx.enable = kernel_selected == "cachyos";
    chaotic.scx.scheduler =
      if kernel_selected == "cachyos"
      then "scx_rusty"
      else null;
  };
}
