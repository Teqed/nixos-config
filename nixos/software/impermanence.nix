{
  lib,
  cfg,
  ...
}: {
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = ["noatime" "mode=755" "uid=0" "gid=0" "size=2G"];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    neededForBoot = true;
    options = ["subvol=@home" "compress=zstd1" "noatime"];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    neededForBoot = true;
    options = ["subvol=@nix" "compress=zstd1" "noatime"];
  };
  swapDevices = [
    {
      label = "swap";
      options = ["nofail"];
    }
  ];
  # By default Nix stores temporary build artifacts in /tmp and since the root (/) is now a 2GB tmpfs we need to
  # configure Nix to use a different location. Otherwise, larger build will result in No enough space left on device errors.
  environment.variables.NIX_REMOTE = "daemon";
  systemd.services.nix-daemon = {
    environment.TMPDIR = "/nix/tmp";
  };
  systemd.tmpfiles.rules = [
    "d /nix/tmp 0755 root root 1d"
  ];
  users.mutableUsers = false;
  users.users = lib.mkMerge (
    [{root.hashedPasswordFile = "/nix/persist/etc/auth/root";}]
    ++ lib.forEach cfg.users (
      u: {"${u}".hashedPasswordFile = "/nix/persist/etc/auth/${u}";}
    )
  );
  environment.persistence."/nix/persist" = {
    enable = true; # NB: Defaults to true, not needed
    # hideMounts = true; # If enabled, it sets the mount option x-gvfs-hide on all the bind mounts.
    directories = [
      "/etc/auth"
      "/etc/nixos"
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      {
        directory = "/var/lib/colord";
        user = "colord";
        group = "colord";
        mode = "u=rwx,g=rx,o=";
      }
    ];
    files = [
      "/etc/machine-id" # machine-id is used by systemd for the journal
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      {
        file = "/var/keys/secret_file";
        parentDirectory = {mode = "u=rwx,g=,o=";};
      }
    ];
    # users = forEach cfg.users (
    #   u: {
    #     "${u}" = {
    #       directories = [
    #         "Downloads"
    #         "Music"
    #         "Pictures"
    #         "Documents"
    #         "Videos"
    #         "VirtualBox VMs"
    #         {
    #           directory = ".gnupg";
    #           mode = "0700";
    #         }
    #         {
    #           directory = ".ssh";
    #           mode = "0700";
    #         }
    #         {
    #           directory = ".nixops";
    #           mode = "0700";
    #         }
    #         {
    #           directory = ".local/share/keyrings";
    #           mode = "0700";
    #         }
    #         ".local/share/direnv"
    #       ];
    #       files = [
    #         ".screenrc"
    #       ];
    #     };
    #   }
    # );
  };
}
