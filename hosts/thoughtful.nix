{nixos-hardware, ...}: {
  imports = [
    ./profiles/common.nix
    ./profiles/desktop.nix
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
  ];
  networking.hostName = "thoughtful"; # /dev/disk/by-partuuid/032b15fe-6dc7-473e-b1a5-d51f4df7ffd6
  networking.hostId = "9936699a";
  nixpkgs.hostPlatform = "x86_64-linux";
  hardware.enableRedistributableFirmware = true;
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
  };
  teq.nixos.impermanence = {
    enable = true;
    btrfs = true;
  };
}
