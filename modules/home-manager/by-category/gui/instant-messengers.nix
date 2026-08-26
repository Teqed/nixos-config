{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      (symlinkJoin {
        name = "vesktop-vaapi";
        paths = [vesktop];
        nativeBuildInputs = [makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/vesktop \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libva]} \
            --add-flags "--enable-features=WaylandWindowDecorations,AcceleratedVideoEncoder"
        '';
      })
      # discord-ptb — removed; preferring vesktop (~570 MiB + electron-40)
      betterdiscordctl
      # discord-krisp # Removed - was provided by chaotic-cx/nyx (discontinued)
      discover-overlay # 600MB / 15MB (gtk+3, gtk-layer-shell)
    ];
  };
}
