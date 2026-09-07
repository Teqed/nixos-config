{
  lib,
  config,
  impermanence,
  ...
}:
let
  cfg = config.teq.nixos;
  label_nixos = cfg.impermanence.label_nixos;
  label_swap = cfg.impermanence.label_swap;
  label_boot = cfg.impermanence.label_boot;
  btrfs_nix = {
    device = "/dev/disk/by-label/${label_nixos}";
    fsType = "btrfs";
    neededForBoot = true;
    options = [
      "subvol=@nix"
      "compress-force=zstd:1"
      "noatime"
    ];
  };
  ext4_nix = {
    device = "/dev/disk/by-label/${label_nixos}";
    fsType = "ext4";
    neededForBoot = true;
    options = [
      "noatime"
    ];
  };
  btrfs_persist = {
    device = "/dev/disk/by-label/${label_nixos}";
    fsType = "btrfs";
    neededForBoot = true;
    options = [
      "subvol=@persist"
      "compress-force=zstd:1"
      "noatime"
    ];
  };
  ext4_persist = {
    depends = [ "/nix" ];
    device = "/nix/persist";
    fsType = "none";
    options = [ "bind" ];
  };
  btrfs_home = {
    device = "/dev/disk/by-label/${label_nixos}";
    fsType = "btrfs";
    neededForBoot = true;
    options = [
      "subvol=@home"
      "compress-force=zstd:1"
      "noatime"
    ];
  };
  ext4_home = {
    depends = [ "/nix" ];
    device = "/nix/home";
    fsType = "none";
    options = [ "bind" ];
  };
in
{
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
    btrfs = lib.mkEnableOption "Use BTRFS for root, home, and persist filesystems. Otherwise, use ext4.";
  };
  config = lib.mkIf cfg.impermanence.enable {
    fileSystems = {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "noatime"
          "mode=755"
          "uid=0"
          "gid=0"
          "size=25%"
        ];
      };
      "/boot" = {
        device = "/dev/disk/by-label/${label_boot}";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
          "noatime"
        ];
      };
      "/nix" = if cfg.impermanence.btrfs then btrfs_nix else ext4_nix;
      "/persist" = if cfg.impermanence.btrfs then btrfs_persist else ext4_persist;
      "/home" = if cfg.impermanence.btrfs then btrfs_home else ext4_home;
    };
    swapDevices = [
      {
        label = label_swap;
        options = [ "nofail" ];
      }
    ];
    environment.variables.NIX_REMOTE = "daemon";
    systemd = {
      services.nix-daemon.environment.TMPDIR = "/nix/tmp";
      tmpfiles.rules = [
        "d /nix/tmp 0755 root root 1d"
      ];
      suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];
    };
    users.mutableUsers = false;
    users.users = lib.mkMerge (
      [ { root.hashedPasswordFile = "/persist/etc/auth/root"; } ]
      ++ lib.forEach config.userinfo.users (u: {
        "${u}".hashedPasswordFile = "/persist/etc/auth/${u}";
      })
    );
    boot.initrd.systemd = {
      enable = lib.mkForce true;
      services.rollback = lib.mkIf cfg.impermanence.btrfs {
        description = "Rollback BTRFS root subvolume to a pristine state";
        wantedBy = [ "initrd.target" ];
        requires = [ "dev-disk-by\\x2dlabel-${label_nixos}.device" ];
        wants = [ "dev-disk-by\\x2dlabel-${label_nixos}.device" ];
        after = [
          "dev-disk-by\\x2dlabel-${label_nixos}.device"
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
              find $snapshot_dir/@home/ -maxdepth 1 -type d | sort | head -n -3 | while IFS= read -r snapshot; do
                  if [[ "$snapshot" == "$snapshot_dir/@home/" ]]; then continue ; fi
                  btrfs subvolume delete "$snapshot"
              done
              umount {$snapshot_dir,$root_dir}
          fi'';
      };

      suppressedUnits = [ "systemd-machine-id-commit.service" ];
    };
    environment.persistence."/persist" = {
      enable = true;

      directories = [
        "/etc/auth"
        "/etc/nixos"
        "/etc/ssh"
        "/etc/NetworkManager/system-connections"
        "/var/cache"
        "/var/db"
        {
          directory = "/var/keys";
          mode = "0700";
        }
        "/var/lib"
        "/var/log"
        "/var/spool"
        {
          directory = "/var/tmp";
          mode = "1777";
        }
        "/usr/systemd-placeholder"
      ];
      files = [
        "/etc/machine-id"
        "/etc/adjtime"
      ];
      users.media = {
        directories = [
          ".cache"
          ".config"
          ".local"
          {
            directory = ".gnupg";
            mode = "0700";
          }
          {
            directory = ".nixops";
            mode = "0700";
          }
          {
            directory = ".ssh";
            mode = "0700";
          }
        ];
      };
      users.teq = {
        directories = [
          ".cache"
          ".claude"
          ".config"
          ".factorio"
          ".local"
          ".mozilla"
          ".vscode-oss"
          ".barony"
          ".pki"
          "Zomboid"
          {
            directory = ".android";
            mode = "0700";
          }
          {
            directory = ".gnupg";
            mode = "0700";
          }
          {
            directory = ".prime";
            mode = "0700";
          }
          {
            directory = ".nixops";
            mode = "0700";
          }
          {
            directory = ".ssh";
            mode = "0700";
          }

          ".zen"
        ];
        files = [
          ".claude.json"
          ".face.icon"
        ];
      };
    };
  };
}
