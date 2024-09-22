{...}: {
  imports = [
    ../hardware/bluetooth.nix
    ../hardware/networking.nix
    ../software/kernel_cachyos.nix
    ../software/locale_en_us_et.nix
    ../software/impermanence.nix
    ../software/desktop.nix
  ];
  networking.hostName = "thoughtful";
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022" "noatime"];
  };
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
  boot = {
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
  system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
