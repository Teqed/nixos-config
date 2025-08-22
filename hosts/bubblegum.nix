{
  nixos-hardware,
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  currentStateVersion = "24.05";
in
{
  imports = [
    ./profiles/common.nix
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    # inputs.nixos-hardware.nixosModules.framework-12-13th-gen-intel # the kmod module doesn't work right for me so we manually impl below
  ];
  networking.hostName = "bubblegum";
  networking.hostId = "48919130"; # head -c 8 /etc/machine-id
  nixpkgs = {
    buildPlatform = "x86_64-linux";
  };
  # From https://github.com/NixOS/nixos-hardware/blob/master/framework/12-inch/common/default.nix a9a7323a067284b5546beef7221ce49a1f3b8d24
  # Fix TRRS headphones missing a mic
  # https://github.com/torvalds/linux/commit/7b509910b3ad6d7aacead24c8744de10daf8715d
  boot.extraModprobeConfig = lib.mkIf (lib.versionOlder config.boot.kernelPackages.kernel.version "6.13.0") ''
    options snd-hda-intel model=dell-headset-multi
  '';

  # Needed for desktop environments to detect display orientation
  hardware.sensor.iio.enable = lib.mkDefault true;

  environment.systemPackages = [ pkgs.framework-tool ];
  # / From
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 12;
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ "pinctrl_tigerlake" ];
      luks.devices = {
        "luks-3247add6-0d03-4f9e-8258-a3dbbb7780ee".device =
          "/dev/disk/by-uuid/3247add6-0d03-4f9e-8258-a3dbbb7780ee";
        "luks-cfc290e0-d912-4c35-979d-8e6a9d6473c7".device =
          "/dev/disk/by-uuid/cfc290e0-d912-4c35-979d-8e6a9d6473c7";
      };
    };
    kernelModules = [ "kvm-intel" ];
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/104f1332-eb7a-4e43-af39-d01cb9329816";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D8F1-705F";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };
  swapDevices = [
    { device = "/dev/disk/by-uuid/8fd5400e-0dad-4ebc-ac53-7cc2120fbc6e"; }
  ];
  home-manager.users.teq.teq.home-manager.gui = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  teq.nixos = {
    gui.enable = true;
    gui.amd = false;
    gui.steam = true;
    media = false;
    cachyos = true;
    blocklist = false;
    impermanence = {
      enable = false;
      btrfs = false;
    };
  };
  networking = {
    firewall = {
      allowedTCPPorts = [
      ];
      allowedUDPPorts = [
      ];
    };
  };
}
