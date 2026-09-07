{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  config = lib.mkIf config.teq.nixos.enable {
    documentation.doc.enable = lib.mkDefault false;

    environment = {
      etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
      pathsToLink = [
        "/share/man"
        "/share/doc"
        "/share/info"
        "/share/zsh"
        "/share/bash-completion"
        "/share/fish"
        "/share/xdg-desktop-portal"
        "/share/applications"
        "/bin"
        "/etc"
      ];
      extraOutputsToInstall = [
        "man"
        "share"
        "icons"
      ];
    };
    nixpkgs.config.allowUnfree = mkDefault true;
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
      ];
    environment.systemPackages = with pkgs; [
      nix-output-monitor
    ];
    programs = {
      fzf = {
        fuzzyCompletion = mkDefault true;
        keybindings = mkDefault true;
      };
    };
    services = {
      languagetool.enable = lib.mkIf config.teq.nixos.gui.enable (mkDefault false);
    };
  };
}
