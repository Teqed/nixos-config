{nixos-hardware, ...}: {
  imports = [
    ./profiles/common.nix
    ./profiles/gui.nix
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
  ];
  networking.hostName = "thoughtful"; # /dev/disk/by-partuuid/032b15fe-6dc7-473e-b1a5-d51f4df7ffd6
  networking.hostId = "9936699a";
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = true;
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 3;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
    initrd.kernelModules = ["amdgpu"];
    kernelModules = ["kvm-amd"];
    kernelParams = [
      "video=DP-1:1920x1080@144" # /sys/class/drm/card0-DP-1/status 143.85 Hz
      "video=DP-2:1920x1080@144" # /sys/class/drm/card0-DP-2/status
      # "video=DP-3:1920x1080@144" # /sys/class/drm/card0-DP-3/status disconnected
      "video=HDMI-A-1:1920x1080@60" # /sys/class/drm/card0-HDMI-A-1/status
      # To figure out the connector names, execute the following command while your monitors are connected:
      # head /sys/class/drm/*/status
      "boot.shell_on_fail" # Drop to root shell on boot failure
      "quiet" # Silences boot messages
      "rd.systemd.show_status=false" # Silences successful systemd messages from the initrd
      "rd.udev.log_level=3" # Silence systemd version number in initrd
      "udev.log_priority=3" # Silence systemd version number
      "boot.shell_on_fail" # If booting fails drop us into a shell where we can investigate
      "splash" # Show a splash screen
      "bgrt_disable" # Don't display the OEM logo after loading the ACPI tables
      "plymouth.use-simpledrm" # Use simple DRM backend for Plymouth
    ];
  };
  environment = {
    fhs = {
      enable = false;
      linkLibs = false;
    };
    lsb = {
      enable = false;
      support32Bit = false;
    };
  };
  teq.nixos = {
    cachyos = true;
    blocklist = false;
    impermanence = {
      enable = true;
      btrfs = true;
    };
  };
}
