# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
{
  fonts = import ./fonts.nix;
  nixcfg = import ./nixcfg.nix;
  locale_en_us_et = import ./locale_en_us_et.nix;
}
