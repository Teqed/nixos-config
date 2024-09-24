{inputs, ...}: {
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example
    # Organized configuration files:
    ./boot.nix
    ./programs.nix
    ./services.nix
    ./users.nix
  ];
  homeManagerModules.nixcfg.enable = true;
  nixosModules.locale_en_us_et.enable = true;
  environment.etc."nix/inputs/nixpkgs".source = "${inputs.nixpkgs}";
  system.stateVersion = "24.05"; # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
}
