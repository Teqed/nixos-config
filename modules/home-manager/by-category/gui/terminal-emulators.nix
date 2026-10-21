{
  lib,
  config,
  pkgs,
  ...
}:
let
  ghosttyNotifyReloadFixed = lib.versionAtLeast pkgs.ghostty.version "1.4";
in
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = [
      (lib.hiPrio pkgs.ghostty)
    ];
    xdg.configFile."systemd/user/app-com.mitchellh.ghostty.service.d/notify.conf" =
      lib.mkIf (!ghosttyNotifyReloadFixed)
        {
          text = ''
            [Service]
            Type=notify
            ExecReload=${pkgs.coreutils}/bin/kill -USR2 $MAINPID
          '';
        };
    warnings = lib.optional ghosttyNotifyReloadFixed "ghostty ${pkgs.ghostty.version} fixes ghostty#14398: remove the notify.conf drop-in from terminal-emulators.nix";
  };
}
