{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      vesktop # 1.8GB / 8MB
      discord-ptb # discocss
      betterdiscordctl
      # discord-krisp # Removed - was provided by chaotic-cx/nyx (discontinued)
      discover-overlay # 600MB / 15MB (gtk+3, gtk-layer-shell)
    ];
  };
}
