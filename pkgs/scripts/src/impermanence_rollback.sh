#! /usr/bin/env bash
snapshot_dir="/mnt/nixos/@snapshots"
root_dir="/mnt/nixos/root"
mkdir -p {/mnt,/mnt/nixos,$root_dir}
mount -t btrfs -L nixos $root_dir
if [[ -e $root_dir/@snapshots ]]; then
    timestamp=$(date "+%Y-%m-%d--%H-%M-%S")
    mkdir -p $snapshot_dir
    mount -t btrfs -o noatime,compress-force=zstd:1,subvol=@snapshots -L nixos $snapshot_dir;
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
fi