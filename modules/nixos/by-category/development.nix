{
  # pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.nixos.enable {
    # services = {
    # };
    programs = {
      ### compilers
      java = {
        enable = lib.mkDefault true;
        binfmt = lib.mkDefault true; # NixOS-specific option
      };
      ### version-management
      git.enable = lib.mkDefault true;
    };
    # environment.systemPackages = with pkgs; [
    # ];
    virtualisation.docker.enable = true;
    users.users.teq.extraGroups = [ "docker" ];
    virtualisation.docker.storageDriver = "btrfs";
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
