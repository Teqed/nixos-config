{lib, modulesPath, pkgs, config, inputs, ...}:
  let
    currentStateVersion = "24.05";
  in {
  imports = [
    ./profiles/common.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  networking.hostName = "jupiter"; # U+2643 ♃ JUPITER
  # Deployment
  services.caddy = {
    enable = true;
    virtualHosts."srd.shatteredsky.net".extraConfig = ''
      tls internal
      reverse_proxy http://localhost:3000
    '';
    # virtualHosts."another.example.org".extraConfig = ''
    #   reverse_proxy unix//run/gunicorn.sock
    # '';
  };
  networking.firewall.allowedTCPPorts = [
      80    # HTTP Caddy
      443   # HTTPS Caddy
      3000  # HTTP Wiki.js
      30000 # HTTP Foundry VTT
      30001 # HTTP Foundry VTT - Noct
    ];
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "wiki-js" ];
    ensureUsers = [{
      name = "wiki-js";
      ensureDBOwnership = true;
    }];
  };
  services.wiki-js = {
    enable = true;
    settings.offline = true;
    settings.db = {
      db  = "wiki-js";
      host = "/run/postgresql";
      type = "postgres";
      user = "wiki-js";
    };
  };
  systemd.services.wiki-js = {
    requires = [ "postgresql.service" ];
    after    = [ "postgresql.service" ];
  };
  containers.foundryvtt-spheres = {
    autoStart = true;
    config = { pkgs, ... }: {
      system.stateVersion = currentStateVersion;
      imports = [ inputs.foundryvtt.nixosModules.foundryvtt ];
      services.foundryvtt = {
        enable = true;
        hostName = "foundry.shatteredsky.net";
        routePrefix = "spheres";
        minifyStaticFiles = true;
        # port = 30000; # Default port
        proxyPort = 443;
        proxySSL = true;
        upnp = false;
        package = inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_11;
      };
    };
  };
  containers.foundryvtt-noctuae = {
    autoStart = true;
    config = { pkgs, ... }: {
      system.stateVersion = currentStateVersion;
      imports = [ inputs.foundryvtt.nixosModules.foundryvtt ];
      services.foundryvtt = {
        enable = true;
        hostName = "foundry.shatteredsky.net";
        routePrefix = "noct";
        minifyStaticFiles = true;
        port = 30001;
        proxyPort = 443;
        proxySSL = true;
        upnp = false;
        package = inputs.foundryvtt.packages.${pkgs.system}.foundryvtt_12;
      };
    };
  };
  # Implementation
  users.users = lib.mkMerge (
    [{root.initialHashedPassword = "$2b$05$2ckfv7WhD4dCuDK9DZi1MuDT6lOLJI9xDVZEAze2/sjw0lODXYCh6";}]
    ++ lib.forEach config.userinfo.users (
      u: {"${u}".initialHashedPassword = "$2b$05$2ckfv7WhD4dCuDK9DZi1MuDT6lOLJI9xDVZEAze2/sjw0lODXYCh6";}
    )
  );
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkForce "aarch64-linux";
  boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_scsi" ];
  boot.loader.grub = {
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.initrd.systemd.enable = false;
  services.openssh.enable = true;
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];
  system.stateVersion = currentStateVersion;
  documentation.man.generateCaches = false;
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "128M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/@" = {
                    mountpoint = "/";
                  };
                  "/@home" = {
                    mountOptions = [ "compress=zstd" ];
                    mountpoint = "/home";
                  };
                  "/@nix" = {
                    mountOptions = [ "compress=zstd" "noatime" ];
                    mountpoint = "/nix";
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap = {
                      swapfile.size = "20M";
                      swapfile2.size = "20M";
                      swapfile2.path = "rel-path";
                    };
                  };
                };
                mountpoint = "/partition-root";
                swap = {
                  swapfile = {
                    size = "20M";
                  };
                  swapfile1 = {
                    size = "20M";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}