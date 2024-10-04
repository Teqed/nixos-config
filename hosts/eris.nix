{...}: {
  imports = [
    ./profiles/usb.nix
  ];
  config = {
    networking.hostName = "eris"; # U+2BF0 ⯰ ERIS FORM ONE
    teq.nixos.desktop.enable = true;
    teq.nixos.desktop.amd = true;
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
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["umask=0077"];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };
      };
    };
  };
}
