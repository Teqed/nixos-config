{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.enable {
    home.packages = with pkgs; [
      lsof # Lsof lists file information about files opened by processes
      grc # Generic text colouriser
      trash-cli
      catimg # Insanely fast image printing in your terminal
      chafa # Terminal graphics for the 21st century
      hyperfine # Command-line benchmarking tool
      ### nix:
      nix-output-monitor
      nix-tree
      ### filesystems:
      sshfs # programs.sftpman ?
      ### text:
      colordiff
      ### pagers:
      most # Supports multiple windows and can scroll left and right. "Why settle for less?"
      moar # Nice-to-use pager for humans
      less # More advanced file pager than 'more'. Included by default
      ov # Feature-rich terminal-based text viewer
    ];
    programs = {
      nix-index.enable = lib.mkDefault true; # integrate with shell's command-not-found functionality
      nix-index-database.comma.enable = lib.mkDefault true; # optional to also wrap and install comma
      direnv = {
        enable = lib.mkDefault true;
        nix-direnv = {
          enable = lib.mkDefault true;
        };
      };
      tmux = {
        enable = true;
        mouse = lib.mkDefault true;
        # keymode = lib.mkDefault "vi"; # default is "emacs"
        # extraConfig = builtins.readFile (./. + "/tmux.conf");
        # plugins = with pkgs; [
        #   tmuxPlugins.cpu
        #   {
        #     plugin = tmuxPlugins.resurrect;
        #     extraConfig = "set -g @resurrect-strategy-nvim 'session'";
        #   }
        #   {
        #     plugin = tmuxPlugins.continuum;
        #     extraConfig = ''
        #       set -g @continuum-restore 'on'
        #       set -g @continuum-save-interval '60' # minutes
        #     '';
        #   }
        # ];
      };
      zellij = {
        enable = lib.mkDefault true;
        # settings = { };
      };
      lesspipe.enable = lib.mkDefault true;
      fastfetch = {
        enable = lib.mkDefault true; # 700MB / 10MB (xfconf 400MB, imagemagick 300MB, python3 200MB)
        # settings = { };
      };
      fd.enable = lib.mkDefault true;
      zoxide.enable = lib.mkDefault true;
      fzf.enable = lib.mkDefault true;
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
          # verbose = true;
        };
      };
      thefuck.enable = lib.mkDefault true; # corrects previous command
      bat = {
        # Cat(1) clone with syntax highlighting and Git integration
        enable = lib.mkDefault true;
        config = {
          # --paging=never --style=plain'
          map-syntax = [
            "*.jenkinsfile:Groovy"
            "*.props:Java Properties"
          ];
          pager = "less -FR";
          theme = "TwoDark";
        };
        extraPackages = with pkgs.bat-extras; [batdiff batman batgrep batwatch];
        # syntaxes = {
        #   gleam = {
        #     src = pkgs.fetchFromGitHub {
        #       owner = "molnarmark";
        #       repo = "sublime-gleam";
        #       rev = "2e761cdb1a87539d827987f997a20a35efd68aa9";
        #       hash = "sha256-Zj2DKTcO1t9g18qsNKtpHKElbRSc9nBRE2QBzRn9+qs=";
        #     };
        #     file = "syntax/gleam.sublime-syntax";
        #   };
        # };
        # themes = {
        #   dracula = {
        #     src = pkgs.fetchFromGitHub {
        #       owner = "dracula";
        #       repo = "sublime"; # Bat uses sublime syntax for its themes
        #       rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
        #       sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
        #     };
        #     file = "Dracula.tmTheme";
        #   };
        # };
      };
      ### text:
      ripgrep.enable = lib.mkDefault true;
      ### filesystems:
      sftpman = {
        enable = lib.mkDefault true;
        # mounts = { };
      };
    };
  };
}
