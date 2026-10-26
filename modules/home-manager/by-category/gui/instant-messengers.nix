{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      (symlinkJoin {
        name = "vesktop-vaapi";
        paths = [
          (vesktop.override {
            withTTS = config.teq.home-manager.tts;
          })
        ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/vesktop \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libva ]} \
            --add-flags "--enable-features=WaylandWindowDecorations,AcceleratedVideoEncoder"
        '';
      })
      betterdiscordctl
      discover-overlay
    ];
  };
}
