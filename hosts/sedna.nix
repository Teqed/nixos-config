{...}: {
  imports = [
    ./profiles/vm.nix
    ./profiles/common.nix
    ./profiles/desktop.nix
  ];
  config = {
    networking.hostName = "sedna"; # U+2BF2 ⯲ SEDNA
  };
}
