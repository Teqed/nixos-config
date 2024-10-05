{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  inherit (lib) mkDefault;
in {
  options.teq.nixos = {
    programs = lib.mkEnableOption "Teq's NixOS Programs configuration defaults.";
  };
  config = lib.mkIf cfg.programs {
    # security.sudo.enable = false; # TODO: Disable sudo in favor of doas
    security.doas = {
      enable = true;
      extraRules = [
        {
          users = ["teq"]; # TODO: Add userinfo list variable
          keepEnv = true;
          persist = true;
        }
      ];
    };
    # documentation.man.enable = false; # Whether to install manual pages. This also includes man outputs. # We may want these
    # documentation.man.generateCaches = false; # Whether to generate the manual page index caches. This allows searching for a page or keyword using utilities like apropos(1) and the -k option of man(1).
    # documentation.doc.enable = false; # Whether to install documentation distributed in packages’ /share/doc. Usually plain text and/or HTML. This also includes “doc” outputs.
    environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";

    nixpkgs.config.allowUnfree = mkDefault true; # TODO: Move all unfree packages into allowUnfreePredicate
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        # TODO: Add additional package names here
      ];

    environment.systemPackages = with pkgs; [
      logiops
      ltex-ls
      diction
      nuspell
      aspell
      enchant
      gspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      hunspell
      hunspellDicts.en_US
      # hunspellDictsChromium.en_US # Not usable as a package
      nix-output-monitor # nix output monitor
    ];

    programs = {
      git.enable = true;

      fzf = {
        fuzzyCompletion = mkDefault true; # NixOS-specific option
        keybindings = mkDefault true; # NixOS-specific option
      };

      mosh.enable = mkDefault true;

      java = {
        enable = mkDefault true;
        binfmt = mkDefault true; # NixOS-specific option
      };
    };
  };
}
