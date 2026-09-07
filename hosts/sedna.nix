{ ... }: {
  imports = [
    ./profiles/vm.nix
    ./profiles/common.nix
  ];
  config = {
    networking.hostName = "sedna";
  };
}
