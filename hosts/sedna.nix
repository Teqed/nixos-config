{
  modulesPath,
  nixos-hardware,
  impermanence,
  nix-flatpak,
  ...
}: {
  imports = [
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    impermanence.nixosModules.impermanence
    nix-flatpak.nixosModules.nix-flatpak
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  networking.hostName = "sedna"; # U+2BF2 ⯲ SEDNA
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022" "noatime"];
  };
  boot = {
    loader = {
      systemd-boot.enable = true;
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
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };
  home-manager.users.teq = {};
  # home-manager.users = lib.forEach userinfo.users (u: {
  #   "${u}" = {};
  # });
  teq.nixos.enable = true;
  teq.nixos.impermanence = true; # Enable impermanence on BTRFS partition labeled "nixos"
  teq.nixos.desktop.enable = true;
  teq.nixpkgs = true;
}
