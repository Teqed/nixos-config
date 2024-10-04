{nixos-hardware, ...}: {
  imports = [
    ./profiles/common.nix
    ./profiles/desktop.nix
    ./profiles/impermanence.nix
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
  ];
  networking.hostName = "thoughtful"; # /dev/disk/by-partuuid/032b15fe-6dc7-473e-b1a5-d51f4df7ffd6
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 3;
    efi.canTouchEfiVariables = true;
  };
  services.xserver.videoDrivers = ["amdgpu"]; # Use the amdgpu driver for AMD GPUs
  boot = {
    initrd.kernelModules = ["amdgpu"]; # Make the kernel use the correct driver early
    # Hardware configuration -------------------
    # initrd.availableKernelModules = ["ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk"];
    # initrd.kernelModules = [];
    # kernelModules = ["kvm-amd"];
    # extraModulePackages = [];
    # ------------------------------------------
    # kernelParams = [
    # "video=DP-1:1920x1080@144" # /sys/class/drm/card0-DP-1/status 143.85 Hz
    # "video=DP-2:1920x1080@144" # /sys/class/drm/card0-DP-2/status
    # "video=DP-3:1920x1080@144" # /sys/class/drm/card0-DP-3/status disconnected
    # "video=HDMI-A-1:1920x1080@60" # /sys/class/drm/card0-HDMI-A-1/status
    # To figure out the connector names, execute the following command while your monitors are connected:
    # head /sys/class/drm/*/status
    # ];
  };
  # xdg.portal.wlr.settings.screencast.output_name = "HDMI-A-1";
}
