{modulesPath, ...}: {
  imports = [
    ./hardware/vm.nix
    ./hardware/networking.nix
    ./software/kernel_cachyos.nix
    ./software/locale_en_us_et.nix
    ./software/impermanence.nix
    ./software/desktop.nix
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
  system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
