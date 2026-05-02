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
    documentation.doc.enable = lib.mkDefault false; # /share/doc HTML/PDF docs (~50-100 MiB); per-package docs still readable via `nix-shell -p <pkg>` if needed
    # documentation.man.generateCaches = false; # fish tab completion uses `man -k` for argument descriptions
    # documentation.man.enable = false; # Used for for `man <cmd>` lookups
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
    environment.extraOutputsToInstall = ["man" "share" "icons"]; # Removed "info" and "doc" — rarely browsed; man pages still kept
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
      # error: lint `box_pointers` has been removed: it does not detect other kinds of allocations, and existed only for historical reasons
      # error: could not compile `clipcat-base` (lib) due to 1 previous error
      # clipcat.enable = lib.mkDefault true; # Clipcat clipboard daemon.
      languagetool.enable = lib.mkIf config.teq.nixos.gui.enable (mkDefault false); # LanguageTool server, a multilingual spelling, style, and grammar checker that helps correct or paraphrase texts. Default off — saves ~390 MiB closure; enable per-host if needed.
    };
  };
}
