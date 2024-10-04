{...}: {
  imports = [
    ./profiles/vm.nix
  ];
  config = {
    networking.hostName = "sedna"; # U+2BF2 ⯲ SEDNA
    teq.nixos.desktop.enable = true;
    teq.nixos.desktop.amd = true;
  };
}
