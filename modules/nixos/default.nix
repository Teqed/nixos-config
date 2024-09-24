# Add your reusable NixOS modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
{
  fonts = import ./fonts.nix;
  kernel = import ./kernel.nix;
  nix-ld = import ./nix-ld.nix;
  locale_en_us_et = import ./locale_en_us_et.nix;
}
