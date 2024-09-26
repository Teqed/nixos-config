{
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager;
in {
  options.teq.home-manager = {
    paths = lib.mkEnableOption "Teq's NixOS Paths configuration defaults.";
  };
  config = lib.mkIf cfg.paths {
    home = {
      preferXdgDirectories = lib.mkDefault true;
      sessionPath = lib.mkDefault ["$HOME/.local/bin"];
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
    # xdg.configFile."nixpkgs/config.nix".source = ./.config/nixpkgs/config.nix;
    # xdg.configFile."nix/nix.conf".source = ./.config/nix/nix.conf;
  };
}
