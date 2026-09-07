{
  pkgs,
  lib,
  config,
  ...
}:
let

  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-VSlays/D5FtiI8vsj2Eu19lxY8Mkgu0+7K6OAhzc+30=";
  };
in
{
  config = lib.mkMerge [
    (lib.mkIf config.teq.home-manager.enable {
      programs.eza = {
        enable = lib.mkDefault true;
        extraOptions = [
          "--group-directories-first"
          "--color-scale"
          "--color=auto"
          "--hyperlink"
          "--extended"
          "--classify"
          "--header"
          "--mounts"
        ];
        git = lib.mkDefault true;
        icons = lib.mkDefault "auto";
      };
    })
    (lib.mkIf config.teq.home-manager.gui {
      programs = {
        xplr = {
          enable = lib.mkDefault true;
        };
        yazi = {
          enable = lib.mkDefault true;
          shellWrapperName = "y";
          settings.theme = {
            flavor = {
              use = lib.mkDefault "catppuccin-mocha";
            };
          };
          flavors = {
            catppuccin-mocha = lib.mkDefault "${yaziFlavors}/catppuccin-mocha.yazi";
          };
        };
      };
    })
  ];
}
