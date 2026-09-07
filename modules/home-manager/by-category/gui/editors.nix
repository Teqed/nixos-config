{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.home-manager.gui {
    home.packages = with pkgs; [
      aseprite
      zed-editor
      kdePackages.kate
    ];
    programs = {
      vscodium = {
        enable = lib.mkDefault true;
        package = lib.mkDefault pkgs.vscodium-fhs;

        profiles.default.extensions = with pkgs; [ vscode-extensions.rust-lang.rust-analyzer ];
      };
    };
  };
}
