# shellcheck shell=bash
# impermanence-rollback: snapshot @home/@persist then reset @home.
snapshot_dir="/mnt/nixos/@snapshots"
root_dir="/mnt/nixos/root"
mkdir -p /mnt /mnt/nixos "$root_dir"
mountpoint -q "$root_dir" || mount -t btrfs -L nixos "$root_dir"
if [[ -e "$root_dir/@snapshots" ]]; then
  timestamp=$(date "+%Y-%m-%d--%H-%M-%S")
  mkdir -p "$snapshot_dir"
  mountpoint -q "$snapshot_dir" || mount -t btrfs -o noatime,compress-force=zstd:1,subvol=@snapshots -L nixos "$snapshot_dir"
  if [[ -e "$root_dir/@home" ]]; then
    mkdir -p "$snapshot_dir/@home"
    btrfs subvolume snapshot "$root_dir/@home" "$snapshot_dir/@home/$timestamp"
    btrfs subvolume delete "$root_dir/@home"
    btrfs subvolume create "$root_dir/@home"
  fi
  if [[ -e "$root_dir/@persist" ]]; then
    mkdir -p "$snapshot_dir/@persist"
    btrfs subvolume snapshot "$root_dir/@persist" "$snapshot_dir/@persist/$timestamp"
  fi
  # Keep only the 10 newest snapshots per subvolume.
  for keep_dir in "$snapshot_dir/@home" "$snapshot_dir/@persist"; do
    if [[ ! -d "$keep_dir" ]]; then
      continue
    fi
    find "$keep_dir/" -maxdepth 1 -type d | sort | head -n -10 | while IFS= read -r snapshot; do
      if [[ "$snapshot" == "$keep_dir/" ]]; then
        continue
      fi
      btrfs subvolume delete "$snapshot"
    done
  done
  umount "$snapshot_dir" "$root_dir"
fi
