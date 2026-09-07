{
  modulesPath,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
  ];
  config = {
    nix = {
      optimise.automatic = true;
      optimise.dates = [ "03:45" ];
      gc = {
        automatic = true;
        dates = "daily";
        options = "--delete-older-than 2d";
      };
    };
    nix.extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
    isoImage.edition = "plasma6";
    boot.zfs.forceImportRoot = false;
    services.openssh.settings.PermitRootLogin = lib.mkForce "yes";

    home-manager.sharedModules = [ { nix.registry = lib.mkForce { }; } ];
    environment.systemPackages = with pkgs; [
      maliit-framework
      maliit-keyboard
      kdePackages.kpmcore
      calamares-nixos
      calamares-nixos-extensions
      glibcLocales
    ];
    i18n.supportedLocales = [ "all" ];
  };
}
