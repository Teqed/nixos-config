{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  config = lib.mkIf config.teq.nixos.enable {
    # documentation.man.enable = false; # Whether to install manual pages. This also includes man outputs. # We may want these
    # documentation.man.generateCaches = false; # Whether to generate the manual page index caches. This allows searching for a page or keyword using utilities like apropos(1) and the -k option of man(1).
    # documentation.doc.enable = false; # Whether to install documentation distributed in packages’ /share/doc. Usually plain text and/or HTML. This also includes “doc” outputs.
    environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
    environment.pathsToLink = [
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
    environment.extraOutputsToInstall = ["info" "man" "share" "icons" "doc"]; # Entries listed here will be appended to the meta.outputsToInstall attribute.
    nixpkgs.config.allowUnfree = mkDefault true; # TODO: Move all unfree packages into allowUnfreePredicate
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        # TODO: Add additional package names here
      ];
    environment.systemPackages = with pkgs; [
      nix-output-monitor # Processes output of Nix commands to show helpful and pretty information
    ];
    programs = {
      fzf = {
        fuzzyCompletion = mkDefault true; # fuzzy completion
        keybindings = mkDefault true; # NixOS-specific option
      };
    };
    services = {
      clipcat.enable = lib.mkDefault true; # Clipcat clipboard daemon.
      languagetool.enable = mkDefault true; # LanguageTool server, a multilingual spelling, style, and grammar checker that helps correct or paraphrase texts.
    };
  };
}
