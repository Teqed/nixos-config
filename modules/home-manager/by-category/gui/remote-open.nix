{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.teq.home-manager;
  remote-open-handler = pkgs.writeShellApplication {
    name = "remote-open-handler";
    runtimeInputs = with pkgs; [ xdg-utils ];
    text = ''
      while IFS= read -r url; do
        case "$url" in
          http://* | https://*) xdg-open "$url" || true ;;
        esac
      done
    '';
  };
  remote-open-listener = pkgs.writeShellApplication {
    name = "remote-open-listener";
    runtimeInputs = [
      pkgs.socat
      remote-open-handler
    ];
    text = ''
      exec socat -u "TCP-LISTEN:46521,fork,reuseaddr" EXEC:remote-open-handler
    '';
  };
  remote-copy-listener = pkgs.writeShellApplication {
    name = "remote-copy-listener";
    runtimeInputs = with pkgs; [
      socat
      wl-clipboard
    ];
    text = ''
      exec socat -u "TCP-LISTEN:46522,fork,reuseaddr" EXEC:wl-copy
    '';
  };
  remote-paste-listener = pkgs.writeShellApplication {
    name = "remote-paste-listener";
    runtimeInputs = with pkgs; [
      socat
      wl-clipboard
    ];
    text = ''
      exec socat -U "TCP-LISTEN:46523,fork,reuseaddr" EXEC:"wl-paste --no-newline"
    '';
  };
  mkListener = name: exe: {
    Unit.Description = "remote-${name} seat listener";
    Service = {
      ExecStart = lib.getExe exe;
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
in
{
  config = lib.mkIf (cfg.enable && cfg.gui) {
    systemd.user.services = {
      remote-open-listener = mkListener "open" remote-open-listener;
      remote-copy-listener = mkListener "copy" remote-copy-listener;
      remote-paste-listener = mkListener "paste" remote-paste-listener;
    };
  };
}
