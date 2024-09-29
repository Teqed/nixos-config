{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager;
  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-W56r4LMepQj0vW1tayx0qA43ZhZEQ09ukZ8IlQMFMe0=";
  };
in {
  options.teq.home-manager = {
    programs = lib.mkEnableOption "Teq's Home-Manager Programs configuration defaults.";
  };
  config = lib.mkIf cfg.programs {
    systemd.user.startServices = lib.mkDefault "sd-switch"; # Nicely reload system units when changing configs
    services = {
      kdeconnect.enable = lib.mkDefault true; # 1GB / 23MB
      # remmina.enable = true; # 900MB / 15MB (freerdp 700MB, spice-gtk 600MB)
    };
    programs = {
      nix-index-database.comma.enable = lib.mkDefault true; # optional to also wrap and install comma
      nix-index.enable = lib.mkDefault true; # integrate with shell's command-not-found functionality
      home-manager.enable = lib.mkDefault true;
      direnv = {
        enable = lib.mkDefault true;
        nix-direnv = {
          enable = lib.mkDefault true;
        };
      };
      eza = {
        enable = lib.mkDefault true;
        extraOptions = [
          "--group-directories-first"
          "--header"
        ];
        git = lib.mkDefault true;
        icons = lib.mkDefault true;
      };
      atuin = {
        enable = lib.mkDefault true;
        # settings = { };
      };
      bat = {
        enable = lib.mkDefault true;
        # config = { };
      };
      bash = {
        enable = lib.mkDefault true;
        enableVteIntegration = lib.mkDefault true;
        # historyControl = # one of "erasedups", "ignoredups", "ignorespace", "ignoreboth"
        historyFile = lib.mkDefault "$HOME/.local/share/history/bash_history"; # "${config.xdg.dataHome}/zsh/zsh_history"
        historyFileSize = lib.mkDefault 1000000;
        historySize = lib.mkDefault 1000000;
        historyIgnore = lib.mkDefault ["rm *" "pkill *" "ls" "cd" "exit"];
        # blesh, a full-featured line editor written in pure Bash
        initExtra = lib.mkBefore ''
          source ${pkgs.blesh}/share/blesh/ble.sh
        '';
        # interactiveShellInit = "";
        # loginShellInit = "";
        # shellInit = "";
        # shellAliases = { };
        # functions = { };
        # plugins = [ ];
      };
      # programs.tmux = {
      #   enable = true;
      #   extraConfig = builtins.readFile (./. + "/tmux.conf");
      # };
      vscode = {
        enable = lib.mkDefault true; # 1.44GB / 400MB (mesa 800MB)
        package = lib.mkDefault pkgs.vscodium;
        # enableUpdateCheck = lib.mkDefault false;
        # enableExtensionUpdateCheck = lib.mkDefault false;
        userSettings = {
          "window.dialogStyle" = "custom";
          "window.customTitleBarVisibility" = "auto";
          "window.titleBarStyle" = "custom";
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
        };
        # extensions = with pkgs; [vscode-extension-jnoortheen-nix-ide];
      };
      lesspipe.enable = lib.mkDefault true;
      fastfetch = {
        enable = lib.mkDefault true; # 700MB / 10MB (xfconf 400MB, imagemagick 300MB, python3 200MB)
        # settings = { };
      };
      # obs-studio.enable = true; # 3.53GB
      btop = {
        enable = lib.mkDefault true;
        # settings = { };
        # extraConfig = " ";
      };
      fd.enable = lib.mkDefault true;
      gh.enable = lib.mkDefault true; # / GitHub Desktop
      jq.enable = lib.mkDefault true;
      # ssh.enable = true;
      # dircolors.enable = true;
      foot = {
        enable = lib.mkDefault true;
        # settings = { };
      };
      go = {
        enable = lib.mkDefault true; # 200MB / 200MB
        # packages = { };
      };
      helix = {
        enable = lib.mkDefault true; # 400MB / 200MB (marksman 200MB / 20MB)
        extraPackages = [pkgs.marksman];
      };
      micro = {
        enable = lib.mkDefault true;
        # settings = { };
      };
      nushell.enable = lib.mkDefault true;
      pyenv.enable = lib.mkDefault true;
      pylint.enable = lib.mkDefault true;
      rbenv.enable = lib.mkDefault true;
      readline = {
        enable = lib.mkDefault true;
        # variables = { };
        # extraConfig = " ";
        # bindings = { "\\C-h" = "backward-kill-word"; }
      };
      ripgrep.enable = lib.mkDefault true;
      sftpman = {
        enable = lib.mkDefault true;
        # mounts = { };
      };
      # starship.enable = true; # Prompt
      vim.enable = lib.mkDefault true; # 570MB / 75MB (vim-full 570MB / 90KB)
      # wezterm = {
      #   enable = lib.mkDefault true; # 230MB / 160MB
      #   package = lib.mkDefault wezterm-flake.packages.${pkgs.system}.default;
      #   # colorSchemes = { };
      #   # extraConfig = " ";
      # };
      yazi = {
        enable = lib.mkDefault true; # 426MB / 20MB (imagemagick, ffmegthumbnailer)
        settings.theme = {
          flavor = {
            use = lib.mkDefault "catppuccin-mocha";
          };
        };
        flavors = {
          catppuccin-mocha = lib.mkDefault "${yaziFlavors}/catppuccin-mocha.yazi";
        };
      };
      zoxide.enable = lib.mkDefault true;
      # thunderbird.enable = true; # profiles needs to be set
      java.enable = true; # Duplicated from NixOS configuration - NixOS can use binfmt # 900 MB / 600 MB
      firefox.enable = lib.mkDefault true; # 1.6GB / 300MB
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
      zsh = {
        enable = lib.mkDefault true;
        autosuggestion.enable = lib.mkDefault true;
        # Add to your system configuration to get completion for system packages (e.g. systemd).
        # environment.pathsToLink = [ "/share/zsh" ];
        enableVteIntegration = lib.mkDefault true;
        # dirHashes = {
        #   docs  = "$XDG_DOCUMENTS_DIR";
        #   vids  = "$XDG_VIDEOS_DIR";
        #   dl    = "$XDG_DOWNLOADS_DIR";
        # };
        dotDir = lib.mkDefault ".config/zsh";
        # envExtra = "" # Extra commands that should be added to .zshenv.
        history = {
          append = lib.mkDefault true;
          expireDuplicatesFirst = lib.mkDefault true;
          extended = lib.mkDefault true;
          ignorePatterns = lib.mkDefault ["rm *" "pkill *"];
          path = lib.mkDefault "$HOME/.local/share/history/zsh_history"; # "${config.xdg.dataHome}/zsh/zsh_history"
          save = lib.mkDefault 1000000;
          size = lib.mkDefault 1000000;
        };
        historySubstringSearch.enable = lib.mkDefault true;
        # initExtraFirst = "" # Commands that should be added to top of .zshrc.
        # initExtra = "" # Extra commands that should be added to .zshrc.
        # localVariables = {} # Extra local variables defined at the top of .zshrc.
        # loginExtra = " " # Extra commands that should be added to .zlogin.
        # logoutExtra = " " # Extra commands that should be added to .zlogout.
        # oh-my-zsh ... Options to configure oh-my-zsh.
        # plugins = [] # Plugins to source in .zshrc.
        # prezto ... Options to configure prezto.
        # profileExtra = " " # Extra commands that should be added to .zprofile.
        # sessionVariables = { } # Environment variables that will be set for zsh session.
        # shellAliases = {}
        # shellGlobalAliases # Similar to programs.zsh.shellAliases, but are substituted anywhere on a line.
        syntaxHighlighting.enable = lib.mkDefault true;
        # zplug ... Options to configure zplug.
        # zprof.enable = true; # zsh manager for profiling.
        # zsh-abbr.enable = true; # zsh manager for auto-expanding abbreviations.

        # Use XDG
        # interactiveShellInit = ''
        #   export HISTFILE=$HOME/.local/share/history/zsh_history
        #   export HISTSIZE=100000
        #   export SAVEHIST=100000
        # '';
        # loginShellInit
        # ohMyZsh ...
        # promptInit
        # setOptions
      };
      fzf.enable = lib.mkDefault true;
      fish = {
        enable = lib.mkDefault true;
        # interactiveShellInit = "";
        # loginShellInit = "";
        # shellInit = "";
        # useBabelfish = true; NixOS-only option
        # preferAbbrs = true; # If enabled, abbreviations will be preferred over aliases when other modules define aliases for fish.
        # shellAbbrs = { }; # An attribute set that maps aliases (the top level attribute names in this option) to abbreviations. Abbreviations are expanded with the longer phrase after they are entered.
        # shellAliases = { }; # An attribute set that maps aliases (the top level attribute names in this option) to command strings or directly to build outputs.
        # functions = { };
        # plugins = [ ]; # The plugins to source in conf.d/99plugins.fish.
      };
    };
  };
}
