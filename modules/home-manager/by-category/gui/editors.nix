{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      aseprite # 117MB / 20MB (harfbuzz 70MB / 3MB)
      zed-editor_git # 230MB / 160MB
      kdePackages.kate # 1.4GB / 40MB (ktexteditor)
    ];
    programs = {
      vscode = {
        enable = lib.mkDefault true; # 1.44GB / 400MB (mesa 800MB)
        package = lib.mkDefault pkgs.vscodium-fhs;
        # enableUpdateCheck = lib.mkDefault false;
        # enableExtensionUpdateCheck = lib.mkDefault false;
        # userSettings = {
        #   "window.dialogStyle" = "custom";
        #   "window.customTitleBarVisibility" = "auto";
        #   "window.titleBarStyle" = "custom";
        #   "nix.enableLanguageServer" = true;
        #   "nix.serverPath" = "nixd";
        # };
        # extensions = with pkgs; [vscode-extension-jnoortheen-nix-ide];
      };
    };
  };
}
