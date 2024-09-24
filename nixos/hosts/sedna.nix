{modulesPath, ...}: {
  imports = [
    ../hardware/vm.nix
    ../hardware/networking.nix
    ../software/impermanence.nix
    ../software/desktop.nix
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
