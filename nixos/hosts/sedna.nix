{
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    ../hardware/vm.nix
    ../software/impermanence.nix
    ../software/desktop.nix
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-gpu-amd
    inputs.nixos-hardware.nixosModules.common-pc
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.impermanence.nixosModules.impermanence
    inputs.nix-flatpak.nixosModules.nix-flatpak
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
  };
}
