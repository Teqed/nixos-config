{...}: {
  additions = final: _prev: import ../pkgs final.pkgs;
  modifications = final: prev: {
    # jdrouhard/mosh fork: adds SSH agent forwarding (enabled by default),
    # Unicode 16 wcwidth, undercurl/strikethrough/dim, extra OSC 52 types.
    mosh = prev.mosh.overrideAttrs (old: {
      version = "1.4.0-jdrouhard-2025-08-23";
      src = final.fetchFromGitHub {
        owner = "jdrouhard";
        repo = "mosh";
        rev = "3d613c845cae0b8966a5d5dbadf2639a9e2f6fd8"; # patched branch
        hash = "sha256-I0YlND+B7MigFKQg+nnTFQb/li+D5oe/CFwoAc9eODg=";
      };
      # Drop nixpkgs' protobuf3-23.x fetchpatch — already merged into this fork
      # (configure.ac already uses AX_CXX_COMPILE_STDCXX([17]) unconditionally).
      patches = builtins.filter builtins.isPath old.patches;
    });

    # Historical entries (now resolved upstream):
    #   - ffmpeg_7-full alias to ffmpeg_7 (was a hotfix for withXevd/withXeve build failure)
    #   - _7zz useUasm override (NixOS/nixpkgs#353272, fixed 2024-11)
  };
}
