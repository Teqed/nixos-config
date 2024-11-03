{...}: {
  additions = final: _prev: import ../pkgs final.pkgs;
  modifications = final: prev: {
    # Hotfixes ffmpeg ; https://github.com/NixOS/nixpkgs/pull/353198
    # ffmpeg_7-full = prev.ffmpeg_7-full.override {
    #   withXevd = false;
    #   withXeve = false;
    # };
    ffmpeg_7-full = prev.ffmpeg_7;
    # Hotfixes #353119 ; "Build failure: _7zz" ; https://github.com/NixOS/nixpkgs/issues/353119
    # Resolved by #353272 ; "_7zz: disable UASM properly" ; https://github.com/NixOS/nixpkgs/pull/353272
    _7zz = prev._7zz.override { useUasm = true; };
  };
}