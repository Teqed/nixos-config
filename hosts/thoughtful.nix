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
    ];
  };

  fileSystems."/mnt/nvme0n1" = {
    device = "/dev/disk/by-label/samsung-990-pro";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
    ];
  };

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
    btop-rocm
    inputs.agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
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

  teq.nixos = {
    samba = true;
    media = false;
    cachyos = true;
    blocklist = false;
    impermanence = {
      enable = true;
      btrfs = true;
    };
    buildServer = {
      enable = true;
      pullKeys.bubblegum = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3IZpWJ13UifP6520LBn8+DA28XPBycCaupUxMP54m/ root@bubblegum";
    };
    agent = {
      enable = true;
      hub.enable = true;
      lists = {
        "repo-nixos-config" = [
          "teq"
          "agent+claude"
          "agent+codex"
        ];
        ops = [
          "teq"
          "agent+claude"
          "agent+codex"
        ];
      };
      proxyKeys."agent@bubblegum" =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILl2Uuhv5q5X1rcncx3k1+z3Rld46HNUBaNR1eNdgzSe mail:agent@bubblegum";
    };
    notify.server.enable = true;
  };

  age.secrets."wg0" = {
    file = ../secrets/wg0.age;
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

    ollama = {
      package = pkgs.ollama-rocm;

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
    hostName = "thoughtful";
    hostId = "9936699a";
    firewall = {
      allowedTCPPorts = [
        5000
        6555
        8283
        11434
      ];
      allowedUDPPorts = [
        8283
        11434
      ];
    };
  };
}
