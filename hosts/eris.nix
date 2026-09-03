{ ... }: {
  imports = [
    ./profiles/usb.nix
    ./profiles/common.nix
  ];
  config = {
    networking.hostName = "eris"; # U+2BF0 ⯰ ERIS FORM ONE
  };
}
