{ inputs }:
{
  llm-agents = final: _prev: {
    llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};
  };
  additions = final: _prev: import ../pkgs final.pkgs;
  modifications = final: prev: {
    mosh = prev.mosh.overrideAttrs (old: {
      version = "1.4.0-jdrouhard-2025-08-23";
      src = final.fetchFromGitHub {
        owner = "jdrouhard";
        repo = "mosh";
        rev = "3d613c845cae0b8966a5d5dbadf2639a9e2f6fd8";
        hash = "sha256-I0YlND+B7MigFKQg+nnTFQb/li+D5oe/CFwoAc9eODg=";
      };

      patches = builtins.filter builtins.isPath old.patches;
    });
  };

  prime-agent-tweaks = final: prev: {
    llm-agents = prev.llm-agents // {
      prime-agent =
        let
          unpatched = prev.llm-agents.prime-agent;
        in
        final.runCommand unpatched.name
          {
            inherit (unpatched) meta;
            passthru = unpatched.passthru or { };
          }
          ''
            cp -r ${unpatched} $out
            chmod -R u+w $out
            shopt -s globstar
            hits=0
            for f in $out/lib/prime-agent/packages/coding-agent/dist/**/*.js; do
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
  };
}
