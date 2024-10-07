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
        "noatime" # Under read intensive work-loads, specifying noatime significantly improves performance because no new access time information needs to be written. https://btrfs.readthedocs.io/en/latest/btrfs-man5.html#notes-on-generic-mount-options
      ];
    };
    fileSystems."/persist" = {
      device = "/dev/disk/by-label/${label_nixos}";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@persist" # BTRFS subvolume for persistent data. Snapshots are stored in @snapshots/@persist and are deleted after 30 days.
        "compress-force=zstd:1"
        "noatime"
      ];
    };
    fileSystems."/home" = {
      device = "/dev/disk/by-label/${label_nixos}";
      fsType = "btrfs";
      neededForBoot = true;
      options = [
        "subvol=@home" # BTRFS subvolume for user home directories. Replaced with empty subvolume on boot. Copies are stored in @snapshots/@home and are deleted after 30 days.
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
    environment.variables.NIX_REMOTE = "daemon"; # By default Nix stores temporary build artifacts in /tmp and since the root (/) is now a tmpfs we need to configure Nix to use a different location.
    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp"; #  Otherwise, a larger build could result in No enough space left on device errors.
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
            find $snapshot_dir/@home/ -maxdepth 1 -type d | sort | head -n -3 | while IFS= read -r snapshot; do
                if [[ "$snapshot" == "$snapshot_dir/@home/" ]]; then continue ; fi
                btrfs subvolume delete "$snapshot"
            done
            find $snapshot_dir/@persist/ -maxdepth 1 -type d | sort | head -n -5 | while IFS= read -r snapshot; do
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
        "/var/log"
        "/var/lib/bluetooth"
        "/var/lib/nixos"
        "/var/lib/systemd/coredump"
        "/var/lib/lxd"
        "/var/lib/docker"
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
        # "/etc/ssh/ssh_host_rsa_key"
        # "/etc/ssh/ssh_host_rsa_key.pub"
        # "/etc/ssh/ssh_host_ed25519_key"
        # "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/adjtime" # Contains descriptive information about the hardware mode clock setting and clock drift factor. The file is read and write by hwclock.
        {
          file = "/var/keys/secret_file";
          parentDirectory = {mode = "u=rwx,g=,o=";};
        }
      ];
      users.teq = {
        # TODO: Make generic to userconfig
        # hideMounts = true;
        directories = [
          ".cache"
          ".config"
          # ".config/gtk-3.0" # fuse mounted from /nix/dotfiles/Plasma/.config/gtk-3.0
          # ".config/gtk-4.0" # to /home/$USERNAME/.config/gtk-3.0
          # ".config/KDE"
          # ".config/kde.org"
          # ".config/plasma-workspace"
          # ".config/xsettingsd"
          {
            directory = ".gnupg";
            mode = "0700";
          }
          # ".local"
          ".local/bin"
          ".local/games"
          ".local/lib"
          ".local/opt"
          ".local/share"
          # ".local/share/direnv"
          # ".local/share/baloo"
          # ".local/share/dolphin"
          # ".local/share/kactivitymanagerd"
          # ".local/share/kate"
          # ".local/share/klipper"
          # ".local/share/konsole"
          # ".local/share/kscreen"
          # ".local/share/kwalletd"
          # ".local/share/kxmlgui5"
          # ".local/share/RecentDocuments"
          # ".local/share/sddm"
          {
            directory = ".local/share/keyrings";
            mode = "0700";
          }
          ".local/state"
          # ".local/state/wireplumber"
          # ".local/state/yazi"
          ".local/user-dirs"
          ".mozilla"
          {
            directory = ".nixops";
            mode = "0700";
          }
          # ".pki" # ?
          # ".rbenv" # ? Move
          {
            directory = ".ssh";
            mode = "0700";
          }
          ".vscode-oss"
          # "VirtualBox VMs"
        ];
        files = [
          ".face.icon"
          ".gtkrc-2.0"
          ".screenrc"
          # ".config/akregatorrc"
          # ".config/baloofileinformationrc"
          # ".config/baloofilerc"
          # ".config/bluedevilglobalrc"
          # ".config/device_automounter_kcmrc"
          # ".config/dolphinrc"
          # ".config/filetypesrc"
          # ".config/gtkrc"
          # ".config/gtkrc-2.0"
          # ".config/gwenviewrc"
          # ".config/kactivitymanagerd-pluginsrc"
          # ".config/kactivitymanagerd-statsrc"
          # ".config/kactivitymanagerd-switcher"
          # ".config/kactivitymanagerdrc"
          # ".config/katemetainfos"
          # ".config/katerc"
          # ".config/kateschemarc"
          # ".config/katevirc"
          # ".config/kcmfonts"
          # ".config/kcminputrc"
          # ".config/kconf_updaterc"
          # ".config/kded5rc"
          # ".config/kdeglobals"
          # ".config/kgammarc"
          # ".config/kglobalshortcutsrc"
          # ".config/khotkeysrc"
          # ".config/kmixrc"
          # ".config/konsolerc"
          # ".config/kscreenlockerrc"
          # ".config/ksmserverrc"
          # ".config/ksplashrc"
          # ".config/ktimezonedrc"
          # ".config/kwinrc"
          # ".config/kwinrulesrc"
          # ".config/kxkbrc"
          # ".config/mimeapps.list"
          # ".config/partitionmanagerrc"
          # ".config/plasma-localerc"
          # ".config/plasma-nm"
          # ".config/plasma-org.kde.plasma.desktop-appletsrc"
          # ".config/plasmanotifyrc"
          # ".config/plasmarc"
          # ".config/plasmashellrc"
          # ".config/PlasmaUserFeedback"
          # ".config/plasmawindowed-appletsrc"
          # ".config/plasmawindowedrc"
          # ".config/powermanagementprofilesrc"
          # ".config/spectaclerc"
          # ".config/startkderc"
          # ".config/systemsettingsrc"
          # ".config/Trolltech.conf"
          # ".config/user-dirs.dirs"
          # ".config/user-dirs.locale"
          # ".local/share/krunnerstaterc"
          # ".local/share/user-places.xbel"
          # ".local/share/user-places.xbel.bak"
          # ".local/share/user-places.xbel.tbcache"
          # ".local/state/arkstaterc"
          # ".local/state/dolphinstaterc"
          # ".local/state/katestaterc"
          # ".local/state/kfontviewstaterc"
          # ".local/state/khelpcenterstaterc"
          # ".local/state/konsolestaterc"
          # ".local/state/lesshst"
          # ".local/state/plasmashellstaterc"
          # ".local/state/systemsettingsstaterc"
          # ".local/state/xdg-desktop-portal-kdestaterc"
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
# --option 'extra-substituters' 'https://chaotic-nyx.cachix.org/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
# reboot
# Additional imperative notes:
# - mkdir .local/state/history # else history files can't be written

