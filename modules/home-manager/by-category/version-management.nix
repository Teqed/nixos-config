{
  # pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.enable {
    programs = {
      gh.enable = lib.mkDefault true; # GitHub CLI
      git = {
        enable = lib.mkDefault true; # 300MB / 70MB (python3 200MB, perl 100MB)
        # prompt = true; # NixOS-specific option
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
          };
        };
      };
    };
  };
}