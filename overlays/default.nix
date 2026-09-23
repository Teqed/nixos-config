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
}
