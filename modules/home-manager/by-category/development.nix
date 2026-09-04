{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    # Universal CLI — useful on any host, including headless servers over SSH.
    (lib.mkIf config.teq.home-manager.enable {
      home.packages = with pkgs; [
        claude-code
        prime-agent
        lazygit # small Go TUI for git
        jujutsu # jj VCS
        jjui
        lazyjj
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
          settings = {
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
    # Dev-adjacent utilities. Language toolchains live in per-project
    # devshells; see templates/ for starters.
    (lib.mkIf config.teq.home-manager.dev {
      home.packages = with pkgs; [
        grpcurl
        goaccess
      ];
    })
  ];
}
