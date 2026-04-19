{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.teq.home-manager.enable {
      programs = {
        readline = {
          enable = lib.mkDefault true;
          # TODO: Migrate .inputrc into config here
          # variables = { };
          # extraConfig = " ";
          # bindings = { "\\C-h" = "backward-kill-word"; }
        };
      };
    })
    (lib.mkIf config.teq.home-manager.gui {
      home.packages = with pkgs; [
        notcurses # 700MB / 10MB (ffmpeg)
      ];
    })
  ];
}
