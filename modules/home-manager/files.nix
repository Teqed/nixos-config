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
    # .config/bash/aliases.sh
    home.file.".config/bash/aliases.sh".source = ./sources/.config/bash/aliases.sh;
    # .config/bash/banner.sh
    home.file.".config/bash/banner.sh".source = ./sources/.config/bash/banner.sh;
    # .config/bash/functions.sh
    home.file.".config/bash/functions.sh".source = ./sources/.config/bash/functions.sh;
    # .config/bash/prompt.bash
    home.file.".config/bash/prompt.bash".source = ./sources/.config/bash/prompt.bash;
    # .config/bash/functions.d/cheat.sh
    home.file.".config/bash/functions.d/cheat.sh".source = ./sources/.config/bash/functions.d/cheat.sh;
    # .config/bash/functions.d/coloring.bash
    home.file.".config/bash/functions.d/coloring.bash".source = ./sources/.config/bash/functions.d/coloring.bash;
    # .config/bash/functions.d/extract.sh
    home.file.".config/bash/functions.d/extract.sh".source = ./sources/.config/bash/functions.d/extract.sh;
    # .config/bash/functions.d/lfcd.sh
    home.file.".config/bash/functions.d/lfcd.sh".source = ./sources/.config/bash/functions.d/lfcd.sh;
    # .config/bash/functions.d/mkcdr.sh
    home.file.".config/bash/functions.d/mkcdr.sh".source = ./sources/.config/bash/functions.d/mkcdr.sh;
    # .config/bash/functions.d/pecho.bash
    home.file.".config/bash/functions.d/pecho.bash".source = ./sources/.config/bash/functions.d/pecho.bash;
    # .config/bash/functions.d/ttitle.bash
    home.file.".config/bash/functions.d/ttitle.bash".source = ./sources/.config/bash/functions.d/ttitle.bash;
    # .config/chromium/policies/managed/defaultExtensions.json
    home.file.".config/chromium/policies/managed/defaultExtensions.json".source = ./sources/.config/chromium/policies/managed/defaultExtensions.json;
    # .config/brave/policies/managed/DisableBraveRewardsWalletAI.json
    home.file.".config/brave/policies/managed/DisableBraveRewardsWalletAI.json".source = ./sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
    # home.file.".local/share/hunspell/en_US.aff".source = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.aff";
    # home.file.".local/share/hunspell/en_US.dic".source = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.dic";
  };
}
