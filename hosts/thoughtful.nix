{
  inputs,
  nixpkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.impermanence.nixosModules.impermanence
    inputs.nix-flatpak.nixosModules.nix-flatpak
  ];
  networking.hostName = "thoughtful";
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022" "noatime"];
  };
  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 10;
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
    kernelParams = [
      # "video=DP-1:1920x1080@144" # /sys/class/drm/card0-DP-1/status 143.85 Hz
      # "video=DP-2:1920x1080@144" # /sys/class/drm/card0-DP-2/status
      # "video=DP-3:1920x1080@144" # /sys/class/drm/card0-DP-3/status disconnected
      # "video=HDMI-A-1:1920x1080@60" # /sys/class/drm/card0-HDMI-A-1/status
      # To figure out the connector names, execute the following command while your monitors are connected:
      # head /sys/class/drm/*/status
    ];
  };
  # xdg.portal.wlr.settings.screencast.output_name = "HDMI-A-1";
  nixpkgs.hostPlatform = nixpkgs.lib.mkDefault "x86_64-linux";
  teq.nixos.all = true; # Enable all of Teq's NixOS configuration defaults.
  teq.nixos.impermanence = true; # Enable impermanence on BTRFS partition labeled "nixos"
  teq.nixos.desktop.enable = true; #
  teq.nixpkgs = true; # Enable Teq's Nixpkgs configuration defaults.
}
