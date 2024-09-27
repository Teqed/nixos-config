{
  lib,
  config,
  ...
}: let
  cfg = config.teq.nixos;
  name = config.home.username;
in {
  options.teq.nixos = {
    persistence = lib.mkEnableOption "Teq's NixOS Persistence configuration defaults.";
  };
  config.home.persistence = lib.mkIf cfg.persistence {
    "/persist/home/${name}" = {
      # hideMounts = true;
      directories = [
        # ".local"
        ".local/user-dirs"
        ".local/bin"
        ".local/lib"
        ".local/share"
        ".local/opt"
        ".local/games"
        # ".local/state"
        # ".config"
        # ".cache"
        # "VirtualBox VMs"
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".nixops";
          mode = "0700";
        }
        {
          directory = "${config.xdg.dataHome}/keyrings";
          mode = "0700";
        }
        "${config.xdg.dataHome}/direnv"
      ];
      files = [
        ".screenrc"
      ];
      allowOther = true;
    };
  };
}
