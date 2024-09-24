# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
{
  imports = [
    ./fonts.nix
    ./kernel.nix
    ./nix-ld.nix
    ./locale_en_us_et.nix
  ];
}
