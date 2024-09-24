{modulesPath, ...}: {
  imports = [
    ../hardware/vm.nix
    ../hardware/networking.nix
    ../software/desktop.nix
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
        configurationLimit = 10;
      };
    };
  };
}
