_: {
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

  prime-agent-tweaks = final: prev: {
    prime-agent = let
      unpatched = prev.prime-agent;
    in
      final.runCommand unpatched.name {
        inherit (unpatched) meta;
        passthru = unpatched.passthru or {};
      } ''
        cp -r ${unpatched} $out
        chmod -R u+w $out

        shopt -s globstar
        hits=0
        for f in $out/lib/node_modules/@earendil-works/pi-coding-agent/dist/**/*.js; do
          if grep -qF 'return START_HINTS[' "$f"; then
            substituteInPlace "$f" --replace-fail \
              'return START_HINTS[Math.floor(random() * START_HINTS.length)] ?? START_HINTS[0];' \
              'return "";'
            hits=$((hits + 1))
          fi
        done
        if [ "$hits" -lt 1 ]; then
          echo "prime-agent-tweaks: START_HINTS pattern not found; upstream changed?" >&2
          exit 1
        fi

        for f in $out/bin/*; do
          sed -i "s|${unpatched}|$out|g" "$f"
        done
      '';
  };
}
