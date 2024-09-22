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
  programs = {
    home-manager.enable = true;
    git.enable = true;
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
    remmina.enable = true;
    # ssh.enable = true;
    # dircolors.enable = true;
    fish = {
      enable = true;
      # settings = { };
    };
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
  };
}
