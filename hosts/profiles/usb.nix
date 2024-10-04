{
  modulesPath,
  pkgs,
  ...
}: let
  label_nixos = "usb_nixos";
  label_boot = "usb_boot";
in {
  imports = [
    ./common.nix
    ./impermanence.nix
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
  ];
  config = {
    teq.nixos.impermanence.label_nixos = label_nixos;
    teq.nixos.impermanence.label_boot = label_boot;
    nix.optimise.automatic = true;
    nix.optimise.dates = ["03:45"];
    nix.settings.auto-optimise-store = true;
    nix.gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };
    nix.extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
    isoImage.edition = "plasma6";
    environment.systemPackages = with pkgs; [
      # FIXME: using Qt5 builds of Maliit as upstream has not ported to Qt6 yet
      maliit-framework
      maliit-keyboard
      # Calamares for graphical installation
      libsForQt5.kpmcore
      calamares-nixos
      calamares-nixos-extensions
      # Get list of locales
      glibcLocales
    ];
    # Support choosing from any locale
    i18n.supportedLocales = ["all"];
    disko.devices = {
      disk = {
        main = {
          device = "/dev/_sdb_/"; # When using disko-install, we will overwrite this value from the commandline
          type = "disk";
          content = {
            type = "gpt";
            partitions = {
              MBR = {
                type = "EF02"; # for grub MBR
                size = "1M";
                priority = 1; # Needs to be first partition
              };
              ESP = {
                type = "EF00";
                size = "500M";
                extraArgs = ["-Lusb_boot"];
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["umask=0077"];
                  label = label_boot; # name?
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f" "-Lusb_nixos"]; # Override existing partition
                  subvolumes = {
                    "/@home" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/home";
                    };
                    "/@nix" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/nix";
                    };
                    "/@persist" = {
                      mountOptions = ["compress=zstd" "noatime"];
                      mountpoint = "/persist";
                    };
                  };
                  label = label_nixos;
                };
              };
            };
          };
        };
      };
    };
  };
}
