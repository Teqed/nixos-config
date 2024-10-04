{
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager;
in {
  options.teq.home-manager = {
    files = lib.mkEnableOption "Teq's Home-Manager Files configuration defaults.";
  };
  config = lib.mkIf cfg.files {
    # .inputrc
    home.file.".inputrc".source = ./sources/.inputrc;
    # .hushlogin
    home.file.".hushlogin".source = ./sources/.hushlogin;
    # .config/dircolors/dircolors
    home.file.".config/dircolors/dircolors".source = ./sources/.config/dircolors/dircolors;
    # .config/blesh/init.sh
    home.file.".config/blesh/init.sh".source = ./sources/.config/blesh/init.sh;
    # .config/nano/nanorc
    home.file.".config/nano/nanorc".source = ./sources/.config/nano/nanorc;
    # .config/vim/.vimrc
    home.file.".config/vim/.vimrc".source = ./sources/.config/vim/.vimrc;
    # .config/wezterm/wezterm.lua
    home.file.".config/wezterm/wezterm.lua".source = ./sources/.config/wezterm/wezterm.lua;
  };
}
