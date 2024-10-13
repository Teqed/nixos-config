{
  lib,
  config,
  impermanence,
  ...
}: let
  cfg = config.teq.nixos;
  label_nixos = cfg.impermanence.label_nixos;
  label_swap = cfg.impermanence.label_swap;
  label_boot = cfg.impermanence.label_boot;
in {
  imports = [
    impermanence.nixosModules.impermanence
  ];
  options.teq.nixos.impermanence = {
    enable = lib.mkEnableOption "Teq's NixOS Impermanence configuration defaults.";
    label_nixos = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
      description = "The label of the BTRFS root filesystem.";
    };
    label_swap = lib.mkOption {
      type = lib.types.str;
      default = "swap";
      description = "The label of the swap partition.";
    };
    label_boot = lib.mkOption {
      type = lib.types.str;
      default = "BOOT";
      description = "The label of the EFI boot partition.";
    };
  };
  # config = lib.mkIf cfg.impermanence {
  config = {
    teq.nixos.impermanence.enable = true; # Allows other modules to check if impermanence is enabled
    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["noatime" "mode=755" "uid=0" "gid=0" "size=25%"];
    };
    fileSystems."/boot" = {
      device = "/dev/disk/by-label/${label_boot}";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022" "noatime"];
    };
    fileSystems."/nix" = {
      device = "/dev/disk/by-label/${label_nixos}";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@nix" # BTRFS subvolume for Nix store.
        "compress-force=zstd:1" # ZSTD Compression level 1 -- Suitable for NVMe SSDs.
        "noatime" # Under read intensive work-loads, specifying noatime significantly improves performance
      ];
    };
    fileSystems."/persist" = {
      device = "/dev/disk/by-label/${label_nixos}";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@persist" # BTRFS subvolume for persistent data.
        "compress-force=zstd:1"
        "noatime"
      ];
    };
    fileSystems."/home" = {
      device = "/dev/disk/by-label/${label_nixos}";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@home"
        # BTRFS subvolume for user home directories. Replaced with empty subvolume on boot.
        "compress-force=zstd:1"
        "noatime"
      ];
    };
    swapDevices = [
      {
        label = label_swap;
        options = ["nofail"];
      }
    ];
    environment.variables.NIX_REMOTE = "daemon";
    # Move temporary build artifacts from /tmp to /nix/tmp
    # Otherwise, a larger build could result in No enough space left on device errors.
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    systemd.tmpfiles.rules = [
      "d /nix/tmp 0755 root root 1d"
    ];
    users.mutableUsers = false;
    users.users = lib.mkMerge (
      [{root.hashedPasswordFile = "/persist/etc/auth/root";}]
      ++ lib.forEach config.userinfo.users (
        u: {"${u}".hashedPasswordFile = "/persist/etc/auth/${u}";}
      )
    );
    boot.initrd.systemd.enable = lib.mkForce true;
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = ["initrd.target"];
      requires = ["dev-disk-by\\x2dlabel-${label_nixos}.device"];
      wants = ["dev-disk-by\\x2dlabel-${label_nixos}.device"];
      after = [
        "dev-disk-by\\x2dlabel-${label_nixos}.device"
        # "systemd-cryptsetup@enc.service" # LUKS/TPM process
      ];
      before = [
        "sysroot.mount"
      ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        snapshot_dir="/mnt/nixos/@snapshots"
        root_dir="/mnt/nixos/root"
        mkdir -p {/mnt,/mnt/nixos,$root_dir}
        mount -t btrfs -L ${label_nixos} $root_dir
        if [[ -e $root_dir/@snapshots ]]; then
            timestamp=$(date "+%Y-%m-%d--%H-%M-%S")
            mkdir -p $snapshot_dir
            mount -t btrfs -o noatime,compress-force=zstd:1,subvol=@snapshots -L ${label_nixos} $snapshot_dir;
            if [[ -e $root_dir/@home ]]; then
                mkdir -p $snapshot_dir/@home
                btrfs subvolume snapshot $root_dir/@home "$snapshot_dir/@home/$timestamp"
                btrfs subvolume delete $root_dir/@home
                btrfs subvolume create $root_dir/@home
            fi
            if [[ -e $root_dir/@persist ]]; then
                mkdir -p $snapshot_dir/@persist
                btrfs subvolume snapshot $root_dir/@persist "$snapshot_dir/@persist/$timestamp"
            fi
            find $snapshot_dir/@home/ -maxdepth 1 -type d | sort | head -n -10 | while IFS= read -r snapshot; do
                if [[ "$snapshot" == "$snapshot_dir/@home/" ]]; then continue ; fi
                btrfs subvolume delete "$snapshot"
            done
            find $snapshot_dir/@persist/ -maxdepth 1 -type d | sort | head -n -10 | while IFS= read -r snapshot; do
                if [[ "$snapshot" == "$snapshot_dir/@persist/" ]]; then continue ; fi
                btrfs subvolume delete "$snapshot"
            done
            umount {$snapshot_dir,$root_dir}
        fi'';
    };
    environment.persistence."/persist" = {
      enable = true; # Defaults to true
      # hideMounts = true; # If enabled, it sets the mount option x-gvfs-hide on all the bind mounts.
      directories = [
        "/etc/auth"
        "/etc/nixos"
        "/etc/ssh"
        "/etc/NetworkManager/system-connections"
        "/var/cache"
        "/var/db"
        "/var/keys"
        "/var/lib"
        "/var/log"
        "/var/spool"
        "/var/tmp"
      ];
      files = [
        "/etc/machine-id" # machine-id is used by systemd for the journal
        "/etc/adjtime" # Contains descriptive information about the hardware clock.
        { file = "/var/keys/secret_file"; parentDirectory = {mode = "u=rwx,g=,o=";}; }
      ];
      users.media = {
        # TODO: Make generic to userconfig.service_profiles
        hideMounts = true;
        directories = [
          ".cache"
          ".config"
          ".local"
          { directory = ".gnupg"; mode = "0700"; }
          { directory = ".nixops"; mode = "0700"; }
          { directory = ".ssh"; mode = "0700"; }
        ];
      };
      users.teq = {
        # TODO: Make generic to userconfig
        # hideMounts = true;
        directories = [
          ".cache"
          ".config"
          ".local"
          ".mozilla"
          ".vscode-oss"
          { directory = ".gnupg"; mode = "0700"; }
          { directory = ".nixops"; mode = "0700"; }
          { directory = ".ssh"; mode = "0700"; }
          # ".pki" # ?
          # ".rbenv" # ? Move
        ];
        files = [
          ".face.icon"
        ];
        # allowOther = true;
      };
    };
  };
}
# Assumptions: 512MB FAT32 EFI "BOOT", 32GB "swap", BTRFS "nixos"
# sudo su -; swapon -L swap; mkdir -p {/mnt,/mnt/nixos,/mnt/nixos/root,/mnt/tmpfs}; mount -t btrfs -L nixos /mnt/nixos/root;
# for subvol in home nix snapshots persist; do btrfs subvolume create /mnt/nixos/root/@$subvol ; done
# umount /mnt/nixos/root/; mount -t tmpfs -o noatime,mode=755 none /mnt/tmpfs;
# mkdir -p /mnt/tmpfs/{boot,nix,home,persist,var,var/log,etc,etc/{nixos,ssh,auth}}; mount -t vfat -L BOOT /mnt/tmpfs/boot;
# for subvol in nix home persist; do mount -t btrfs -o noatime,compress-force=zstd:1,subvol=@$subvol -L nixos /mnt/tmpfs/$subvol ; done
# mkdir -p /mnt/tmpfs/persist/{var,var/log,etc,etc/{nixos,ssh,auth}};
# for dir in var/log etc/nixos etc/ssh etc/auth; do mount --bind /mnt/tmpfs/persist/$dir /mnt/tmpfs/$dir ; done
# nixos-generate-config --root /mnt/tmpfs # Inspect boot configuration
# mkpasswd -m bcrypt -s >> /mnt/tmpfs/persist/etc/auth/root
# mkpasswd -m bcrypt -s >> /mnt/tmpfs/persist/etc/auth/teq
# git clone https://github.com/Teqed/nixos-config; cd nixos-config
# # enable plasma theming for intial load
# nixos-install --root /mnt/tmpfs --flake .#thoughtful --no-root-passwd
# reboot
# Additional imperative notes:
# - mkdir .local/state/history # else history files can't be written

