{...}: {
  imports = [
    ./profiles/vm.nix
    ./profiles/common.nix
  ];
  config = {
    networking.hostName = "sedna"; # U+2BF2 ⯲ SEDNA
  };
}
