{
  lib,
  config,
  ...
}:
{
  options.teq.home-manager = {
    files = lib.mkEnableOption "Teq's Home-Manager Files configuration defaults.";
  };
  config = lib.mkIf config.teq.home-manager.enable {
    home = {
      file = {
        "_".source = config.lib.file.mkOutOfStoreSymlink "/home/teq/.local/user-dirs";
        ".hushlogin".source = ./sources/.hushlogin;
        ".config/readline/inputrc".source = ./sources/.config/readline/inputrc;
        ".config/dircolors/dircolors".source = ./sources/.config/dircolors/dircolors;
        ".config/blesh/init.sh".source = ./sources/.config/blesh/init.sh;
        ".config/nano/nanorc".source = ./sources/.config/nano/nanorc;
        ".config/vim/.vimrc".source = ./sources/.config/vim/.vimrc;
        ".config/wezterm/wezterm.lua".source = ./sources/.config/wezterm/wezterm.lua;
        ".config/ghostty/config".source = ./sources/.config/ghostty/config;
        ".config/ghostty/ghostty-shaders/my_bloom.glsl".source =
          ./sources/.config/ghostty/ghostty-shaders/my_bloom.glsl;
        ".config/bash/functions.sh".source = ./sources/.config/bash/functions.sh;
        ".config/bash/functions.d/cheat.sh".source = ./sources/.config/bash/functions.d/cheat.sh;
        ".config/bash/functions.d/coloring.bash".source = ./sources/.config/bash/functions.d/coloring.bash;
        ".config/bash/functions.d/extract.sh".source = ./sources/.config/bash/functions.d/extract.sh;
        ".config/bash/functions.d/lfcd.sh".source = ./sources/.config/bash/functions.d/lfcd.sh;
        ".config/bash/functions.d/mkcdr.sh".source = ./sources/.config/bash/functions.d/mkcdr.sh;
        ".config/bash/functions.d/pecho.bash".source = ./sources/.config/bash/functions.d/pecho.bash;
        ".config/bash/functions.d/ttitle.bash".source = ./sources/.config/bash/functions.d/ttitle.bash;
        ".config/chromium/policies/managed/defaultExtensions.json".source =
          ./sources/.config/chromium/policies/managed/defaultExtensions.json;
        ".config/brave/policies/managed/DisableBraveRewardsWalletAI.json".source =
          ./sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
        # ".local/share/hunspell/en_US.aff".source = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.aff";
        # ".local/share/hunspell/en_US.dic".source = "${pkgs.hunspellDicts.en_US}/share/hunspell/en_US.dic";
      };
      # .config/bash/functions.sh # TODO: Convert to Nix config

      # Stale `*.backup-hm` / `*.hm-backup` left by interrupted HM activations block subsequent
      # runs ("would be clobbered by backing up"). Sweep them before HM does its file checks.
      activation.cleanupStaleHmBackups = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        $DRY_RUN_CMD find "$HOME/.config" "$HOME/.local/share" -type f \
          \( -name "*.backup-hm" -o -name "*.hm-backup" \) \
          -delete 2>/dev/null || true
      '';
    };
  };
}
