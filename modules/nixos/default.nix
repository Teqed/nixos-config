{
  __kernel = import ./kernel.nix;
  __nix-ld = import ./nix-ld.nix;
  __i18n_en_us_et = import ./i18n_en_us_et.nix;
  __boot = import ./boot.nix;
  __programs = import ./programs.nix;
  __services = import ./services.nix;
  __networking = import ./networking.nix;
  __desktop = import ./desktop;
  __nixcfg = import ./nixcfg.nix;
}
