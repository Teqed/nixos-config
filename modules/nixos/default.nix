{inputs, ...}:
# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
{
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    # Organized configuration files:
    ./fonts.nix
    ./kernel.nix
    ./nix-ld.nix
    ./locale_en_us_et.nix
    ./boot.nix
    ./programs.nix
    ./services.nix
    ./users.nix
  ];
  # homeManagerModules.nixcfg.enable = true;
  # options.nixosModules.locale_en_us_et.enable = true;
  # documentation.man.enable = false; # Whether to install manual pages. This also includes man outputs.
  documentation.man.generateCaches = false; # Whether to generate the manual page index caches. This allows searching for a page or keyword using utilities like apropos(1) and the -k option of man(1).
  documentation.doc.enable = false; # Whether to install documentation distributed in packages’ /share/doc. Usually plain text and/or HTML. This also includes “doc” outputs.
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
