{
  pkgs,
  lib,
  config,
  ...
}: let
  # XDG_CONFIG_HOME = "${config.xdg.configHome}";
in {
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages = with pkgs; [
      rustup # cargo
      ### interpreters:
      python3 # 165MB / 108MB (gcc 40MB, openssl 40MB, readline 40MB, ncurses 30MB, sqlite 30MB, bash 30MB, etc.)
      ### language-servers:
      bash-language-server # 300MB / 200MB (nodejs 200MB)
      nil
      nixd # Nix language server, based on nix libraries https://github.com/nix-community/nixd
    ];
    programs = {
      jq.enable = lib.mkDefault true;
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
  };
}
