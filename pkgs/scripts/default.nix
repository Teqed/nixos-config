{
  writeShellApplication,
  coreutils,
  util-linux,
  btrfs-progs,
  findutils,
  ...
}:
writeShellApplication {
  name = "impermanence-rollback";
  runtimeInputs = [
    coreutils
    util-linux
    btrfs-progs
    findutils
  ];
  text = builtins.readFile ./src/impermanence_rollback.sh;
}
