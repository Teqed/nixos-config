{
  pkgs,
  lib,
  config,
  ...
}: let
  # XDG_CONFIG_HOME = "${config.xdg.configHome}";
  yaziFlavors = pkgs.fetchFromGitHub {
    owner = "yazi-rs";
    repo = "flavors";
    rev = "main";
    sha256 = "sha256-VSlays/D5FtiI8vsj2Eu19lxY8Mkgu0+7K6OAhzc+30=";
  };
in {
  config = lib.mkIf config.teq.home-manager.enable {
    programs = {
    eza = {
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
      icons = lib.mkDefault true;
    };
    xplr = {
      enable = lib.mkDefault true;
      # extraConfig =
      # plugins =
    };
    yazi = {
      enable = lib.mkDefault true; # 426MB / 20MB (imagemagick, ffmegthumbnailer)
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
  };
}