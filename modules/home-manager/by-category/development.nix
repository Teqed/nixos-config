{
  pkgs,
  lib,
  config,
  osConfig ? null,
  ...
}:
let
  agentEnabled = osConfig != null && (osConfig.teq.nixos.agent.enable or false);
in
{
  config = lib.mkMerge [
    (lib.mkIf config.teq.home-manager.enable {
      home.packages =
        with pkgs;
        lib.optionals (!agentEnabled) [
          llm-agents.claude-code
          llm-agents.prime-agent
          llm-agents.codex
        ]
        ++ [
          lazygit
          jujutsu
          jjui
          lazyjj
          just
          tokei
          scc
          ast-grep
        ];
      programs = {
        jq.enable = lib.mkDefault true;
        gh.enable = lib.mkDefault true;
        git = {
          enable = lib.mkDefault true;

          signing.format = null;
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
    (lib.mkIf config.teq.home-manager.dev {
      home.packages = with pkgs; [
        grpcurl
        goaccess
      ];
    })
  ];
}
