{
  pkgs,
  lib,
  config,
  ...
}: let
  # XDG_CONFIG_HOME = "${config.xdg.configHome}";
in {
  config = lib.mkMerge [
    # Universal CLI — useful on any host, including headless servers over SSH.
    (lib.mkIf config.teq.home-manager.enable {
      home.packages = with pkgs; [
        claude-code
        lazygit # small Go TUI for git
        jujutsu # jj VCS
        jjui
        lazyjj
        gg-jj
        just # task runner
        tokei # code stats
        scc # code counter
        ast-grep # structural grep
      ];
      programs = {
        jq.enable = lib.mkDefault true;
        gh.enable = lib.mkDefault true; # GitHub CLI
        git = {
          enable = lib.mkDefault true; # 300MB / 70MB (python3 200MB, perl 100MB)
          # prompt = true; # NixOS-specific option
          signing.format = null; # Explicitly use 26.05+ default format
          extraConfig = {
            init = {
              defaultBranch = lib.mkDefault "main";
            };
            url = {
              "https://github.com/" = {
                insteadOf = lib.mkDefault [
                  "gh:"
                  "github:"
                ];
              };
              "https://tangled.org/" = {
                insteadOf = lib.mkDefault [
                  "t:"
                  "to:"
                  "tangled:"
                ];
              };
            };
          };
        };
      };
    })
    # Development toolchains and heavier dev-adjacent tooling.
    (lib.mkIf config.teq.home-manager.dev {
      home.packages = with pkgs; [
        rustup # cargo
        ### interpreters:
        python3 # 165MB / 108MB (gcc 40MB, openssl 40MB, readline 40MB, ncurses 30MB, sqlite 30MB, bash 30MB, etc.)
        ### language-servers:
        bash-language-server # 300MB / 200MB (nodejs 200MB)
        nil
        nixd # Nix language server, based on nix libraries https://github.com/nix-community/nixd
        grpcurl
        redisinsight
        goaccess
      ];
      programs = {
        pyenv.enable = lib.mkDefault true;
        ### python-modules:
        pylint.enable = lib.mkDefault true;
        ### ruby-modules:
        rbenv.enable = lib.mkDefault true;
        ### compilers:
        go = {
          enable = lib.mkDefault true; # 200MB / 200MB
          # packages = { };
        };
        java.enable = true; # Duplicated from NixOS configuration - NixOS can use binfmt # 900 MB / 600 MB
      };
    })
  ];
}
