{
  config,
  nixos-hardware,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./profiles/common.nix
    ./profiles/gui.nix
    nixos-hardware.nixosModules.common-pc
    nixos-hardware.nixosModules.common-pc-ssd
    nixos-hardware.nixosModules.common-cpu-amd
    nixos-hardware.nixosModules.common-gpu-amd
  ];
  nixpkgs = {
    # hostPlatform = "aarch64-linux";
    buildPlatform = "x86_64-linux";
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  hardware.cpu.amd.updateMicrocode = true;
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 12;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];
    initrd.kernelModules = [ "amdgpu" ];
    kernelModules = [ "kvm-amd" ];
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
  # Samsung 990 PRO data drive (/dev/nvme0n1, GPT + single ext4 partition).
  # Intended as a base for mapping service storage out of /var/lib via binds/symlinks.
  fileSystems."/mnt/nvme0n1" = {
    device = "/dev/disk/by-label/samsung-990-pro";
    fsType = "ext4";
    options = [
      "nofail" # Don't block boot if the drive is absent.
      "noatime"
    ];
  };

  # VM
  programs.dconf.enable = true;
  users = {
    users.gcis = {
      extraGroups = [ "libvirtd" ];
      group = "gcis";
      isSystemUser = true;
    };
    groups.gcis = { };
  };
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    adwaita-icon-theme
    btop-rocm # Not related to VM -- ROCM support for AMD GPUs
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default # agenix CLI tool
    wireguard-tools
  ];
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };
  # /VM

  teq.nixos = {
    samba = true;
    media = false;
    cachyos = true; # Now using xddxdd/nix-cachyos-kernel
    blocklist = false;
    impermanence = {
      enable = true;
      btrfs = true;
    };
    buildServer.enable = true;
    notify.server.enable = true;
  };

  # Agenix secret management
  age.secrets."wg0" = {
    file = ../secrets/wg0.age;
    # The decrypted file will be available at config.age.secrets."wg0".path
  };
  age.secrets."washing-machien" = {
    file = ../secrets/washing-machien.age;
  };

  vpnNamespaces.wg = {
    enable = true;
    wireguardConfigFile = config.age.secrets."wg0".path;
    accessibleFrom = [
      "10.0.0.0/24"
      "100.64.0.0/10"
    ];
    portMappings = [
      {
        from = 8080;
        to = 8080;
      }
    ];
    openVPNPorts = [
      {
        port = 6881;
        protocol = "both";
      }
    ];
  };
  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "wg";
  };

  services = {
    spice-vdagentd.enable = true;
    # GameCube adapter udev rule
    udev.extraRules = ''
      SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="0337", MODE="0666"
    '';
    moonshine = {
      enable = true;
      user = "teq";
      firewallInterfaces = [ "tailscale0" ];
      settings = {
        name = "thoughtful (moonshine)";
        address = "0.0.0.0";
        webserver = {
          port = 48989;
          port_https = 48984;
          certificate = "$HOME/.config/moonshine/cert.pem";
          private_key = "$HOME/.config/moonshine/key.pem";
        };
        stream = {
          port = 49010;
          video.port = 48998;
          control.port = 48999;
          audio.port = 49000;
        };
        application = [
          {
            title = "Steam Big Picture";
            command = [
              "/run/current-system/sw/bin/steam"
              "steam://open/bigpicture"
            ];
          }
        ];
        application_scanner = [
          {
            type = "steam";
            library = "$HOME/.local/share/Steam";
            command = [
              "/run/current-system/sw/bin/steam"
              "-bigpicture"
              "steam://rungameid/{game_id}"
            ];
          }
        ];
      };
    };
    # puts u in dhe washing machein
    # https://tangled.org/coil-habdle.ebil.club/washing-machien
    washing-machien = {
      enable = true;
      package =
        inputs.washing-machien.packages.${pkgs.stdenv.hostPlatform.system}.washing-machien.overrideAttrs
          (old: {
            patches = (old.patches or [ ]) ++ [ ../patches/washing-machien-session-cache.patch ];
          });
      input = builtins.path { path = ./assets/washing-machien-avatar.jpg; };
      environmentFile = config.age.secrets."washing-machien".path;
    };
    tangled.spindle = {
      enable = true;
      package = inputs.tangled-core.packages.${pkgs.stdenv.hostPlatform.system}.spindle;
      server = {
        hostname = "spindle.shatteredsky.net";
        owner = "did:plc:jrtgsidnmxaen4offglr5lsh";
        dev = true;
      };
    };
    qbittorrent = {
      enable = true;
      webuiPort = 8080;
      torrentingPort = 6881;
      openFirewall = false;
    };
    # parakeet.enable = true;
    ollama = {
      # enable = true;
      package = pkgs.ollama-rocm; # Use ROCm-accelerated package instead of deprecated acceleration option
      # Optional: preload models, see https://ollama.com/library
      loadModels = [ ];
      port = 11434;
      host = "0.0.0.0";
      openFirewall = true;
    };
    open-webui = {
      enable = false;
      openFirewall = true;
    };
    qdrant.enable = false;
    nix-serve = {
      enable = true;
      secretKeyFile = "/var/lib/nix-serve/cache-priv-key.pem";
    };
  };
  networking = {
    hostName = "thoughtful"; # /dev/disk/by-partuuid/032b15fe-6dc7-473e-b1a5-d51f4df7ffd6
    hostId = "9936699a";
    firewall = {
      allowedTCPPorts = [
        5000 # Nix-Serve
        6555 # Spindle
        8283 # Letta
        11434 # Ollama
      ];
      allowedUDPPorts = [
        8283 # Letta
        11434 # Ollama
      ];
    };
  };
  # containers.rsky = {
  #   autoStart = true;
  #   config = { pkgs, ... }: {
  #     system.stateVersion = currentStateVersion;
  #     imports = [ inputs.rsky.nixosModules.default ];
  #     services.rsky-pds = {
  #       enable = true;
  #       environmentFiles = [ "/var/lib/rsky-pds/pds.env" ];
  #       settings = {
  #         PDS_PORT = 2583;
  #         PDS_HOSTNAME = "psi.shatteredsky.net";
  #         PDS_DEV_MODE = "true";
  #       };
  #     };
  #   };
  # };
}
