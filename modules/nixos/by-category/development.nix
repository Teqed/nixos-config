{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.nixos.enable {
    services = {
      postgresql = {
        enable = lib.mkDefault false;
        identMap = ''
            # ArbitraryMapName systemUser DBUser
            superuser_map      root      postgres
            superuser_map      teq       postgres
            superuser_map      postgres  postgres
            # Let other names login as themselves
            superuser_map      /^(.*)$   \1
        '';
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method optional_ident_map
          local all       teq     peer        map=superuser_map
          local all       postgres peer        map=superuser_map
          local sameuser  all     peer        map=superuser_map
        '';
        package = pkgs.postgresql_16;
        settings = {
          # listen_addresses = "*";
          # max_connections = 100;
          # shared_buffers = "128MB";
          # effective_cache_size = "256MB";
          # work_mem = "4MB";
          # maintenance_work_mem = "64MB";
          # max_wal_size = "1GB";
          # min_wal_size = "80MB";
        };
      };
    };
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
      # rar
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
