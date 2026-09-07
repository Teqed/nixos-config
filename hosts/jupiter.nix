{
  lib,
  modulesPath,
  pkgs,
  config,
  inputs,
  ...
}:
let
  currentStateVersion = "24.05";

  mkFoundry =
    pkgs: attrs:
    (pkgs.callPackage "${inputs.foundryvtt}/pkgs/foundryvtt" { }).overrideAttrs (old: old // attrs);
in
{
  imports = [
    ./profiles/common.nix
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  services = {
    scx.enable = false;
    smartd.enable = false;
    caddy = {
      enable = true;
      virtualHosts."srd.shatteredsky.net".extraConfig = ''
        tls internal
        reverse_proxy http://localhost:3000
      '';
    };
    postgresql = {
      enable = true;
      ensureDatabases = [ "wiki-js" ];
      ensureUsers = [
        {
          name = "wiki-js";
          ensureDBOwnership = true;
        }
      ];
    };
    wiki-js = {
      enable = true;
      settings.offline = true;
      settings.db = {
        db = "wiki-js";
        host = "/run/postgresql";
        type = "postgres";
        user = "wiki-js";
      };
    };
    openssh.enable = true;
  };
  networking = {
    hostName = "jupiter";
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [
      80
      443
      30000
      30001
      30002
    ];
  };
  systemd.services.wiki-js = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  containers = {
    foundryvtt-spheres = {
      autoStart = true;
      config = { pkgs, ... }: {
        system.stateVersion = currentStateVersion;
        nixpkgs.config.allowUnfree = true;
        imports = [ inputs.foundryvtt.nixosModules.foundryvtt ];
        services.foundryvtt = {
          enable = true;
          hostName = "foundry.shatteredsky.net";
          routePrefix = "spheres";
          minifyStaticFiles = true;

          proxyPort = 443;
          proxySSL = true;
          upnp = false;
          package = mkFoundry pkgs {
            majorVersion = "11";
            releaseType = "stable";
          };
        };
      };
    };
    foundryvtt-noctuae = {
      autoStart = true;
      config = { pkgs, ... }: {
        system.stateVersion = currentStateVersion;
        nixpkgs.config.allowUnfree = true;
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
          package = mkFoundry pkgs {
            majorVersion = "12";
            releaseType = "stable";
          };
        };
      };
    };
    foundryvtt-jeimuzu = {
      autoStart = true;
      config = { pkgs, ... }: {
        system.stateVersion = currentStateVersion;
        nixpkgs.config.allowUnfree = true;
        imports = [ inputs.foundryvtt.nixosModules.foundryvtt ];
        services.foundryvtt = {
          enable = true;
          hostName = "foundry.shatteredsky.net";
          routePrefix = "jei";
          minifyStaticFiles = true;
          port = 30002;
          proxyPort = 443;
          proxySSL = true;
          upnp = false;
          package = mkFoundry pkgs {
            majorVersion = "13";
            releaseType = "stable";
          };
        };
      };
    };
  };

  users.users = lib.mkMerge (
    [ { root.initialHashedPassword = "$2b$05$2ckfv7WhD4dCuDK9DZi1MuDT6lOLJI9xDVZEAze2/sjw0lODXYCh6"; } ]
    ++ lib.forEach config.userinfo.users (u: {
      "${u}".initialHashedPassword = "$2b$05$2ckfv7WhD4dCuDK9DZi1MuDT6lOLJI9xDVZEAze2/sjw0lODXYCh6";
    })
  );
  nixpkgs = {
    config.allowUnsupportedSystem = true;
    hostPlatform = lib.mkForce "aarch64-linux";
  };
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = true;
        configurationLimit = 1;
      };
      efi.canTouchEfiVariables = false;
    };
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "virtio_scsi"
      ];

      systemd.enable = true;
    };
  };
  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];
  system.stateVersion = currentStateVersion;
  documentation.man.cache.enable = false;
  system.extraDependencies =
    let
      versions = builtins.fromJSON (
        builtins.readFile "${inputs.foundryvtt}/pkgs/foundryvtt/versions.json"
      );
      zip =
        v:
        pkgs.requireFile {
          name = "FoundryVTT${lib.optionalString (lib.versionAtLeast v "13.338") "-Linux"}-${v}.zip";
          inherit (versions.${v}) hash;
          url = "https://foundryvtt.com";
        };
    in
    map zip [
      "11.315"
      "12.343"
      "13.351"
    ];
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
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
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
