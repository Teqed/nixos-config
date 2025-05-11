{
  lib,
  config,
  ...
}: {
  options.teq.home-manager = {
    files = lib.mkEnableOption "Teq's Home-Manager Files configuration defaults.";
  };
  config = lib.mkIf config.teq.home-manager.enable {
    home.file."_".source = config.lib.file.mkOutOfStoreSymlink "/home/teq/.local/user-dirs";
    home.file.".hushlogin".source = ./sources/.hushlogin;
    home.file.".config/readline/inputrc".source = ./sources/.config/readline/inputrc;
    home.file.".config/dircolors/dircolors".source = ./sources/.config/dircolors/dircolors;
    home.file.".config/blesh/init.sh".source = ./sources/.config/blesh/init.sh;
    home.file.".config/nano/nanorc".source = ./sources/.config/nano/nanorc;
    home.file.".config/vim/.vimrc".source = ./sources/.config/vim/.vimrc;
    home.file.".config/wezterm/wezterm.lua".source = ./sources/.config/wezterm/wezterm.lua;
    home.file.".config/ghostty/config".source = ./sources/.config/ghostty/config;
    home.file.".config/ghostty/ghostty-shaders/my_bloom.glsl".source = ./sources/.config/ghostty/ghostty-shaders/my_bloom.glsl;
    # .config/bash/functions.sh # TODO: Convert to Nix config
    home.file.".config/bash/functions.sh".source = ./sources/.config/bash/functions.sh;
    home.file.".config/bash/functions.d/cheat.sh".source = ./sources/.config/bash/functions.d/cheat.sh;
    home.file.".config/bash/functions.d/coloring.bash".source = ./sources/.config/bash/functions.d/coloring.bash;
    home.file.".config/bash/functions.d/extract.sh".source = ./sources/.config/bash/functions.d/extract.sh;
    home.file.".config/bash/functions.d/lfcd.sh".source = ./sources/.config/bash/functions.d/lfcd.sh;
    home.file.".config/bash/functions.d/mkcdr.sh".source = ./sources/.config/bash/functions.d/mkcdr.sh;
    home.file.".config/bash/functions.d/pecho.bash".source = ./sources/.config/bash/functions.d/pecho.bash;
    home.file.".config/bash/functions.d/ttitle.bash".source = ./sources/.config/bash/functions.d/ttitle.bash;
    home.file.".config/chromium/policies/managed/defaultExtensions.json".source = ./sources/.config/chromium/policies/managed/defaultExtensions.json;
    home.file.".config/brave/policies/managed/DisableBraveRewardsWalletAI.json".source = ./sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
    # home.file.".local/share/hunspell/en_US.aff".source = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.aff";
    # home.file.".local/share/hunspell/en_US.dic".source = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.dic";
  };
}
