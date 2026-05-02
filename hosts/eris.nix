{lib, ...}: {
  imports = [
    ./profiles/usb.nix
    ./profiles/common.nix
  ];
  config = {
    networking.hostName = "eris"; # U+2BF0 ⯰ ERIS FORM ONE
    # Break mkDefault tie with installation-device.nix; installer needs root login.
    services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
  };
}
