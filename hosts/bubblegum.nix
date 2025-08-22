{
  nixos-hardware,
  ...
}:
{
  imports = [
    ./profiles/common.nix
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
  ];
  networking.hostName = "bubblegum";
  # networking.hostId = "9936699a"; # head -c 8 /etc/machine-id
  nixpkgs = {
    buildPlatform = "x86_64-linux";
  };
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 12;
      efi.canTouchEfiVariables = true;
    };
    initrd.kernelModules = [ "pinctrl_tigerlake" ];
  };
  home-manager.users.teq.teq.home-manager.gui = true;
  teq.nixos = {
    gui.enable = true;
    gui.amd = false;
    gui.steam = true;
    media = false;
    cachyos = true;
    blocklist = false;
    impermanence = {
      enable = true;
      btrfs = true;
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
