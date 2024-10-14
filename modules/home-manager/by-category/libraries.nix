{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages = with pkgs; [
      notcurses # 700MB / 10MB (ffmpeg)
    ];
    readline = {
      enable = lib.mkDefault true;
      # TODO: Migrate .inputrc into config here
      # variables = { };
      # extraConfig = " ";
      # bindings = { "\\C-h" = "backward-kill-word"; }
    };
  };
}