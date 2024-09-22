{modulesPath, ...}: {
  imports = [
    ./hardware/vm.nix
    ./hardware/networking.nix
    ./software/kernel_cachyos.nix
    ./software/locale_en_us_et.nix
    ./software/desktop.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  networking.hostName = "eris"; # U+2BF0 ⯰ ERIS FORM ONE
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    neededForBoot = true;
  };
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/vda";
        useOSProber = true;
      };
    };
  };
  system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
