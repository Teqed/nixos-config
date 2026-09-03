{
  modulesPath,
  nixos-hardware,
  lib,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  config = {
    # TODO: placeholder; replace with the VM's real hardware configuration
    fileSystems."/" = lib.mkDefault {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };
    fileSystems."/boot" = lib.mkDefault {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };
    services.spice-vdagentd.enable = lib.mkDefault true; # TODO: check if handled by the qemu-guest profile?
    nixpkgs.hostPlatform = "x86_64-linux";
    boot = {
      loader = {
        systemd-boot.enable = true;
        systemd-boot.configurationLimit = 3;
        efi.canTouchEfiVariables = true;
      };
      initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "sr_mod"
        "virtio_blk"
        "virtio_net"
        "virtio_mmio"
        "virtio_scsi"
      ];
      initrd.kernelModules = [
        "virtio_balloon"
        "virtio_console"
        "virtio_rng"
      ];
      kernelModules = [ "kvm-amd" ];
      extraModulePackages = [ ];
    };
  };
}
