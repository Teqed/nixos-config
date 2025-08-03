{nixos-hardware, pkgs, inputs, ...}:
  let
    currentStateVersion = "24.05";
  in {
  imports = [
    ./profiles/common.nix
    ./profiles/gui.nix
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
  ];
  networking.hostName = "thoughtful"; # /dev/disk/by-partuuid/032b15fe-6dc7-473e-b1a5-d51f4df7ffd6
  networking.hostId = "9936699a";
  nixpkgs = {
      # hostPlatform = "aarch64-linux";
      buildPlatform = "x86_64-linux";
  };
  hardware.cpu.amd.updateMicrocode = true;
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 12;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod"];
    initrd.kernelModules = ["amdgpu"];
    kernelModules = ["kvm-amd"];
    kernelParams = [
      # "video=DP-1:1920x1080@144" # /sys/class/drm/card0-DP-1/status 143.85 Hz
      # "video=DP-2:1920x1080@144" # /sys/class/drm/card0-DP-2/status
      # # "video=DP-3:1920x1080@144" # /sys/class/drm/card0-DP-3/status disconnected
      # "video=HDMI-A-1:1920x1080@60" # /sys/class/drm/card0-HDMI-A-1/status
      # To figure out the connector names, execute the following command while your monitors are connected:
      # head /sys/class/drm/*/status
#      "quiet" # Silences boot messages
#      "rd.systemd.show_status=false" # Silences successful systemd messages from the initrd
#      "rd.udev.log_level=3" # Silence systemd version number in initrd
#      "udev.log_priority=3" # Silence systemd version number
#      "boot.shell_on_fail" # If booting fails drop us into a shell where we can investigate
#      "splash" # Show a splash screen
#      "bgrt_disable" # Don't display the OEM logo after loading the ACPI tables
#      "plymouth.use-simpledrm" # Use simple DRM backend for Plymouth
    ];
  };
  # VM
  programs.dconf.enable = true;
  users.users.gcis.extraGroups = [ "libvirtd" ];
  users.users.gcis.group = "gcis";
  users.groups.gcis = {};
  users.users.gcis.isSystemUser = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
    adwaita-icon-theme
    btop.override {rocmSupport = true;} # Not related to VM though
  ];
  virtualisation = { libvirtd = { enable = true; qemu = { swtpm.enable = true; ovmf.enable = true; ovmf.packages = [ pkgs.OVMFFull.fd ]; }; }; spiceUSBRedirection.enable = true; }; services.spice-vdagentd.enable = true;
  # /VM
  teq.nixos = {
    media = false;
    cachyos = true;
    blocklist = false;
    impermanence = {
      enable = true;
      btrfs = true;
    };
  };
  services = {
    ollama = {
      enable = true;
      acceleration = "rocm";
      # Optional: preload models, see https://ollama.com/library
      loadModels = [ ];
    };
    open-webui = {
      enable = true;
      openFirewall = true;
    };
    qdrant.enable = true;
    nix-serve = {
      enable = true;
      secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
    };
  };
  networking = {
    firewall = {
      allowedTCPPorts = [ 5000 ]; # Nix-Serve
    };
  };
  containers.rsky = {
    autoStart = true;
    config = { pkgs, ... }: {
      system.stateVersion = currentStateVersion;
      imports = [ inputs.rsky.nixosModules.default ];
      services.rsky-pds = {
        enable = true;
        environmentFiles = [ "/var/lib/rsky-pds/pds.env" ];
        settings = {
          PDS_PORT = 2583;
          PDS_HOSTNAME = "psi.shatteredsky.net";
          PDS_DEV_MODE = "true";
        };
      };
    };
  };
}
