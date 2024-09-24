# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
{
  imports = [
    ./fonts.nix
    ./nixcfg.nix
    ./locale_en_us_et.nix
  ];
}
