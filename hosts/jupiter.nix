{lib, modulesPath, pkgs, config, ...}: {
  imports = [
    ./profiles/common.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  networking.hostName = "jupiter"; # U+2643 ♃ JUPITER
  # Deployment
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
  system.stateVersion = "24.05";
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