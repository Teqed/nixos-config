{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      vesktop # 1.8GB / 8MB
      # discord # discocss
      discord-krisp # 1.3GB / 300MB (mesa 800MB)
      discover-overlay # 600MB / 15MB (gtk+3, gtk-layer-shell)
    ];
  };
}
