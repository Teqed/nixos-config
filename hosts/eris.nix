{ ... }: {
  imports = [
    ./profiles/usb.nix
    ./profiles/common.nix
  ];
  config = {
    networking.hostName = "eris";
  };
}
