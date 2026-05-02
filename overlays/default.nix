{...}: {
  additions = final: _prev: import ../pkgs final.pkgs;
  modifications = final: prev: {
    # No active modifications.
    # Historical entries (now resolved upstream):
    #   - ffmpeg_7-full alias to ffmpeg_7 (was a hotfix for withXevd/withXeve build failure)
    #   - _7zz useUasm override (NixOS/nixpkgs#353272, fixed 2024-11)
  };
}
