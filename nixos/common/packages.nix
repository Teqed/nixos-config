{pkgs, ...}: {
  # List packages installed in system profile. To search, run: nix search wget
  environment.systemPackages = with pkgs; [
    # (import
    #   (builtins.fetchTarball {
    #     url = "https://github.com/NixOS/nixpkgs/archive/957d95fc8b9bf1eb60d43f8d2eba352b71bbf2be.tar.gz";
    #     sha256 = "sha256:0jkxg1absqsdd1qq4jy70ccx4hia3ix891a59as95wacnsirffsk";
    #   })
    #   { inherit system; }).wezterm
    curl
    micro
    wget
    spice-vdagent
    papirus-icon-theme
    bibata-cursors
    nix-output-monitor
    nil
  ];
  programs.firefox.enable = true; # Install firefox.
  programs = {
    # Git
    git = {
      enable = true;
      prompt = true;
      config = {
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
    # Zsh
    zsh = {
      enable = true;
      autosuggestions = {
        enable = true;
      };
      enableBashCompletion = true;
      # Use XDG
      # histFile = "$HOME/.local/share/zsh/history";
      histFile = "$HOME/.local/share/history/zsh_history";
      hiseSize = 100000;
      # interactiveShellInit = ''
      #   export HISTFILE=$HOME/.local/share/history/zsh_history
      #   export HISTSIZE=100000
      #   export SAVEHIST=100000
      # '';
      # loginShellInit
      # ohMyZsh ...
      # promptInit
      # setOptions
      syntaxHighlighting.enable = true;
    };
    # fish
    fish = {
      enable = true;
      # interactiveShellInit
      # loginShellInit
      # promptInit
      # shellAbbrs
      # shellAliases
      # shellInit
      useBabelfish = true;
    };
    # fzf
    fzf = {
      fuzzyCompletion = true;
      keybindings = true;
    };
    # mosh
    mosh.enable = true;
    # virt-manager
    virt-manager.enable = true;
    # jdk
    java = {
      enable = true;
      binfmt = true;
    };
    # thunderbird
    thunderbird.enable = true;
    # kdeconnect
    kdeconnect.enable = true;
    # appimage
    appimage = {
      enable = true;
      binfmt = true;
      package = pkgs.appimage-run.override {
        extraPkgs = pkgs: [pkgs.ffmpeg pkgs.imagemagick];
      };
    };
  };
}
