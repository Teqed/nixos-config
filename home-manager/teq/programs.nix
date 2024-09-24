{
  inputs,
  pkgs,
  ...
}: let
  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-/EUaaL08K3F0J0Rn9+XgfKm+W8tekdiWsGxkd892BO8=";
  };
in {
  services = {
    kdeconnect.enable = true;
    remmina.enable = true;
  };
  programs = {
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    # programs.tmux = {
    #   enable = true;
    #   extraConfig = builtins.readFile (./. + "/tmux.conf");
    # };
    vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      # extensions = with pkgs; [];
    };
    lesspipe.enable = true;
    fastfetch = {
      enable = true;
      # settings = { };
    };
    obs-studio.enable = true;
    btop = {
      enable = true;
      # settings = { };
      # extraConfig = " ";
    };
    fd.enable = true;
    gh.enable = true; # / GitHub Desktop
    hstr.enable = true;
    jq.enable = true;
    # ssh.enable = true;
    # dircolors.enable = true;
    foot = {
      enable = true;
      # settings = { };
    };
    go = {
      enable = true;
      # packages = { };
    };
    helix = {
      enable = true;
      extraPackages = [pkgs.marksman];
    };
    micro = {
      enable = true;
      # settings = { };
    };
    nix-index.enable = true;
    nushell.enable = true;
    pyenv.enable = true;
    pylint.enable = true;
    rbenv.enable = true;
    readline = {
      enable = true;
      # variables = { };
      # extraConfig = " ";
      # bindings = { "\\C-h" = "backward-kill-word"; }
    };
    ripgrep.enable = true;
    sftpman = {
      enable = true;
      # mounts = { };
    };
    # starship.enable = true; # Prompt
    vim.enable = true;
    wezterm = {
      enable = true;
      package = inputs.wezterm-flake.packages.${pkgs.system}.default;
      # colorSchemes = { };
      # extraConfig = " ";
    };
    yazi = {
      enable = true;
      settings.theme = {
        flavor = {
          use = "catppuccin-mocha";
        };
      };
      flavors = {
        catppuccin-mocha = "${yaziFlavors}/catppuccin-mocha.yazi";
      };
    };
    zoxide.enable = true;
    thunderbird.enable = true;
    java.enable = true; # Duplicated from NixOS configuration - NixOS can use binfmt
    firefox.enable = true;
    git = {
      enable = true;
      # prompt = true; # NixOS-specific option
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        url = {
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
        };
      };
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      # Add to your system configuration to get completion for system packages (e.g. systemd).
      # environment.pathsToLink = [ "/share/zsh" ];
      enableVteIntegration = true;
      # dirHashes = {
      #   docs  = "$XDG_DOCUMENTS_DIR";
      #   vids  = "$XDG_VIDEOS_DIR";
      #   dl    = "$XDG_DOWNLOADS_DIR";
      # };
      dotDir = ".config/zsh";
      # envExtra = "" # Extra commands that should be added to .zshenv.
      history = {
        append = true;
        expireDuplicatesFirst = true;
        extended = true;
        ignorePatterns = ["rm *" "pkill *"];
        path = "$HOME/.local/share/history/zsh_history"; # "${config.xdg.dataHome}/zsh/zsh_history"
        save = 1000000;
        size = 1000000;
        historySubstringSearch.enable = true;
      };
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
      syntaxHighlighting.enable = true;
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
    fzf.enable = true;
    fish = {
      enable = true;
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
}
