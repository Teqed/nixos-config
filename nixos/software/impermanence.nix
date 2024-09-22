{
  mkMerge,
  forEach,
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
    options = ["subvol=@home" "compress=zstd1" "noatime"];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    neededForBoot = true;
    options = ["subvol=@nix" "compress=zstd1" "noatime"];
  };
  fileSystems."/etc/nixos" = {
    depends = ["/nix"];
    device = "/nix/persist/etc/nixos";
    fsType = "none";
    neededForBoot = true;
    options = ["bind"];
  };
  fileSystems."/var/log" = {
    depends = ["/nix"];
    device = "/nix/persist/var/log";
    fsType = "none";
    options = ["bind"];
  };
  swapDevices = [
    {
      label = "swap";
      options = ["nofail"];
    }
  ];
  # By default Nix stores temporary build artifacts in /tmp and since the root (/) is now a 2GB tmpfs we need
  # to configure Nix to use a different location. Otherwise, larger build will result in No enough space left
  # on device errors.
  environment.variables.NIX_REMOTE = "daemon";
  systemd.services.nix-daemon = {
    environment.TMPDIR = "/nix/tmp";
  };
  systemd.tmpfiles.rules = [
    "d /nix/tmp 0755 root root 1d"
  ];
  environment.etc = {
    # Persist files in the /etc directory across reboots.
    "machine-id".source = "/nix/persist/etc/machine-id"; # machine-id is used by systemd for the journal
    "auth".source = "/nix/persist/etc/auth"; # Persist hashed passwords for users
    # Persist the openssh daemon host keys
    "ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
    "ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
    "ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
    "ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";
  };
  users.mutableUsers = false;
  users.users = mkMerge (
    [{root.hashedPasswordFile = "/nix/persist/etc/auth/root";}]
    ++ forEach cfg.users (
      u: {"${u}".hashedPasswordFile = "/nix/persist/etc/auth/${u}";}
    )
  );
}
