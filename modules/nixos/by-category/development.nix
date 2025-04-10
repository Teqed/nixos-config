{
  pkgs,
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
      ecryptfs.enable = lib.mkDefault true;
      gnupg = {
        agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-curses;
        };
      };
    };
    environment.systemPackages = with pkgs; [
      dbeaver-bin
      # blender # blender-hip ?
      httpie
      websocat
      rar
    ];
    virtualisation.docker.enable = true;
    users.users.teq.extraGroups = [ "docker" ];
    virtualisation.docker.storageDriver = "btrfs";
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
}
