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
        ".claude/skills/reader".source = ../../pkgs/harness/skills/reader;
        ".config/readline/inputrc".source = ./sources/.config/readline/inputrc;
        ".config/dircolors/dircolors".source = ./sources/.config/dircolors/dircolors;
        ".config/nano/nanorc".source = ./sources/.config/nano/nanorc;
        ".config/vim/.vimrc".source = ./sources/.config/vim/.vimrc;
        ".config/wezterm/wezterm.lua".source = ./sources/.config/wezterm/wezterm.lua;
        ".config/ghostty/config".source = ./sources/.config/ghostty/config;
        ".config/ghostty/ghostty-shaders/my_bloom.glsl".source =
          ./sources/.config/ghostty/ghostty-shaders/my_bloom.glsl;
        ".config/chromium/policies/managed/defaultExtensions.json".source =
          ./sources/.config/chromium/policies/managed/defaultExtensions.json;
        ".config/brave/policies/managed/DisableBraveRewardsWalletAI.json".source =
          ./sources/.config/brave/policies/managed/DisableBraveRewardsWalletAI.json;
      };

      activation.cleanupStaleHmBackups = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        $DRY_RUN_CMD find "$HOME/.config" "$HOME/.local/share" -type f \
          \( -name "*.backup-hm" -o -name "*.hm-backup" \) \
          -delete 2>/dev/null || true
      '';
    };
  };
}
