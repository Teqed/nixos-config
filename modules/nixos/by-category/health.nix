{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.teq.nixos.health;
  notify = config.teq.nixos.notify;
  smart-ntfy = pkgs.writeShellScript "smart-ntfy" ''
    host=$(${pkgs.nettools}/bin/hostname)
    ${pkgs.curl}/bin/curl -fsS \
      -H "Title: $host: SMART ''${SMARTD_FAILTYPE:-alert} on ''${SMARTD_DEVICE:-?}" \
      -H "Priority: high" \
      -H "Tags: floppy_disk,$host" \
      --data-binary @- \
      ${notify.url}/${notify.topic} >/dev/null
  '';
  btrfsMounts = lib.filter (fs: fs.fsType == "btrfs") (lib.attrValues config.fileSystems);
  onePerDevice = lib.foldl' (
    acc: fs: if acc ? ${fs.device} then acc else acc // { ${fs.device} = fs.mountPoint; }
  ) { } btrfsMounts;
  scrubTargets = lib.attrValues onePerDevice;
in
{
  imports = [ ../health ];
  options.teq.nixos.health = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.teq.nixos.enable;
      description = "flake-health on PATH with a daily ntfy report, smartd with ntfy alerts, monthly btrfs scrub of every btrfs device.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.smartd = {
      enable = lib.mkDefault true;
      autodetect = lib.mkDefault true;
      defaults.monitored = lib.mkDefault "-a -o on -s (S/../.././02|L/../../7/04)";
      notifications.mail = {
        enable = true;
        mailer = "${smart-ntfy}";
        recipient = "ntfy";
      };
    };

    services.btrfs.autoScrub = lib.mkIf (scrubTargets != [ ]) {
      enable = lib.mkDefault true;
      interval = lib.mkDefault "monthly";
      fileSystems = scrubTargets;
    };
  };
}
