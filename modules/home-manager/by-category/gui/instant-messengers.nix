{
  pkgs,
  lib,
  config,
  ...
}:
let
  # electron-bin 43.4.1 drops the Plasma tray icon (electron/electron#52674)
  mkElectron = pkgs.callPackage "${pkgs.path}/pkgs/development/tools/electron/binary/generic.nix" { };
  electron_43_trayfix =
    if lib.versionAtLeast pkgs.electron_43.version "43.5.0" then
      pkgs.electron_43
    else
      mkElectron "43.6.0" {
        x86_64-linux = "3075c82d0749e136bca77563d4dd24e881714d17d98241fafd02320da5d6e237";
        headers = "edf651dd0c9374406501860d6d11ea48c1c671c064c8598fda867b22fd22d5d1";
      };
in
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      (symlinkJoin {
        name = "vesktop-vaapi";
        paths = [
          (vesktop.override {
            withTTS = config.teq.home-manager.tts;
            electron_43 = electron_43_trayfix;
          })
        ];
        nativeBuildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/vesktop \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libva ]} \
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
