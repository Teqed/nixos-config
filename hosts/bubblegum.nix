{
  nixos-hardware,
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
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-pc-laptop
    nixos-hardware.nixosModules.framework-12-13th-gen-intel
  ];
  networking.hostName = "bubblegum";
  networking.hostId = "489919130"; # head -c 8 /etc/machine-id
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
