{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.teq.nixos.enable {
    services = {
      postgresql = {
        enable = lib.mkDefault false;
        identMap = ''
          superuser_map      root      postgres
          superuser_map      teq       postgres
          superuser_map      postgres  postgres
          superuser_map      /^(.*)$   \1
        '';
        authentication = pkgs.lib.mkOverride 10 ''
          local all       teq     peer        map=superuser_map
          local all       postgres peer        map=superuser_map
          local sameuser  all     peer        map=superuser_map
        '';
        package = pkgs.postgresql_16;
        settings = {
        };
      };
    };
    programs = {
      java = lib.mkIf config.teq.nixos.gui.enable {
        enable = lib.mkDefault true;
        binfmt = lib.mkDefault true;
      };

      git.enable = lib.mkDefault true;

      gnupg = {
        agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-curses;
        };
      };
    };
    environment.systemPackages =
      with pkgs;
      [
        android-tools
        httpie
        websocat
      ]
      ++ lib.optionals config.teq.nixos.gui.enable [
        dbeaver-bin
      ];
    users.users.teq.extraGroups = [ "docker" ];
    virtualisation.docker = {
      enable = true;

      storageDriver = if config.teq.nixos.impermanence.btrfs then "btrfs" else "overlay2";
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
  };
}
