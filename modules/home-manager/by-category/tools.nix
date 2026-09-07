{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages =
      with pkgs;
      [
        lsof
        grc
        trash-cli
        hyperfine
        nix-output-monitor
        nix-tree
        sshfs
        colordiff
        most
        moor
        less
        ov
      ]
      ++ lib.optionals config.teq.home-manager.gui [
        catimg
        chafa
      ];
    programs = {
      nix-index.enable = lib.mkDefault true;
      nix-index-database.comma.enable = lib.mkDefault true;
      direnv = {
        enable = lib.mkDefault true;
        nix-direnv = {
          enable = lib.mkDefault true;
        };
      };
      tmux = {
        enable = true;
        mouse = lib.mkDefault true;
      };
      zellij = {
        enable = lib.mkDefault true;
      };
      lesspipe.enable = lib.mkDefault true;
      fastfetch = {
        enable = lib.mkDefault true;
      };
      fd.enable = lib.mkDefault true;
      zoxide.enable = lib.mkDefault true;
      fzf.enable = lib.mkDefault true;
      fzf.historyWidget.command = "";
      skim = {
        enable = lib.mkDefault true;
      };
      translate-shell = {
        enable = lib.mkDefault true;
        settings = {
          hl = "en";
          tl = [
            "es"
            "fr"
            "de"
            "zh"
            "it"
            "ja"
            "ko"
            "no"
          ];
        };
      };
      pay-respects.enable = lib.mkDefault true;
      bat = {
        enable = lib.mkDefault true;
        config = {
          map-syntax = [
            "*.jenkinsfile:Groovy"
            "*.props:Java Properties"
          ];
          pager = "less -FR";
          theme = "TwoDark";
        };
        extraPackages = with pkgs.bat-extras; [
          batdiff
          batman
          batgrep
          batwatch
        ];
      };

      ripgrep.enable = lib.mkDefault true;

      sftpman = {
        enable = lib.mkDefault true;
      };
    };
  };
}
