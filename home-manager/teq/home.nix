# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  # config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    ./packages.nix
    ./programs.nix
  ];
  # xdg.configFile."nixpkgs/config.nix".source = ./.config/nixpkgs/config.nix;
  # xdg.configFile."nix/nix.conf".source = ./.config/nix/nix.conf;
  home = {
    preferXdgDirectories = true;
    sessionPath = ["$HOME/.local/bin"];
    # username = "teq"; # "$USER" by default
    # homeDirectory = "/home/teq"; "$HOME" by default
    # sessionVariables = {
    #   EDITOR = "emacs";
    #   GS_OPTIONS = "-sPAPERSIZE=a4";
    #   FOO = "Hello";
    #   BAR = "${config.home.sessionVariables.FOO} World!";
    # };
    # This option should only be used to manage simple aliases that are compatible across all shells. If you need to use a shell specific feature then make sure to use a shell specific option, for example programs.bash.shellAliases for Bash.
    # shellAliases = {
    #   g = "git";
    #   "..." = "cd ../..";
    # };
    pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      gtk.enable = true;
      x11.enable = true;
      x11.defaultCursor = "Bibata-Modern-Classic";
    };
  };
  # thing = mkMerge [
  #   (mkIf (!config.home.preferXdgDirectories) {
  #     home.file.".inputrc".text = finalConfig;
  #   })
  #   (mkIf config.home.preferXdgDirectories {
  #     xdg.configFile.inputrc.text = finalConfig;
  #     home.sessionVariables.INPUTRC = "${config.xdg.configHome}/inputrc";
  #   })
  # ];
  gtk = {
    enable = true;
    cursorTheme.name = "Bibata-Modern-Classic";
    cursorTheme.size = 24; # Default 16
    # font = "Noto Sans,  10"; null or (submodule)
    # iconTheme = "Papirus-Dark"; # null or (submodule)
  };
  systemd.user.startServices = "sd-switch"; # Nicely reload system units when changing configs
  home.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
