{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.teq.nixos.media;
in {
  options.teq.nixos.media = {
    enable = lib.mkEnableOption "Teq's NixOS Media configuration defaults.";
  };
  config = lib.mkIf cfg.enable {
    services = {
      jellyseerr = {
        enable = true;
        openFirewall = true; # 5055
        # port = 5055; # Default
      };
      bazarr = {
        enable = true;
        openFirewall = true; # 6767
        user = "media"; # defaults to "bazarr"
        group = "media"; # defaults to "bazarr"
        # listenPort = 6767; # Default
      };
      sabnzbd = {
        enable = true;
        openFirewall = true; # 7080
        user = "media"; # defaults to "sabnzbd"
        group = "media"; # defaults to "sabnzbd"
        configFile = "/home/media/.local/state/sabnzbd/sabnzbd.ini";
      };
      radarr = {
        enable = true;
        openFirewall = true; # 7878
        user = "media"; # defaults to "radarr"
        group = "media"; # defaults to "radarr"
        dataDir = "/home/media/.local/state/radarr/.config/Radarr";
      };
      jellyfin = {
        enable = true;
        openFirewall = true; # 8096 # The HTTP/HTTPS ports can be changed in the Web UI, so this option should only be used if they are unchanged, see Port Bindings.
        user = "media"; # defaults to "jellyfin"
        group = "media"; # defaults to "jellyfin"
        dataDir = "/home/media/.local/state/jellyfin";
        configDir = "/home/media/.local/state/jellyfin/config";
        logDir = "/home/media/.local/state/jellyfin/log";
        cacheDir = "/home/media/.cache/jellyfin";
      };
      tautulli = {
        enable = true;
        openFirewall = true; # 8181
        user = "media"; # defaults to "tautulli"
        group = "media"; # defaults to "tautulli"
        dataDir = "/home/media/.local/state/plexpy";
        port = 8181; # Default
        configFile = "/home/media/.local/state/plexpy/config.ini";
      };
      readarr = {
        enable = true;
        openFirewall = true; # 8787
        user = "media"; # defaults to "readarr"
        group = "media"; # defaults to "readarr"
        dataDir = "/home/media/.local/state/readarr/.config/Readarr";
      };
      sonarr = {
        enable = true;
        openFirewall = true; # 8989
        user = "media"; # defaults to "sonarr"
        group = "media"; # defaults to "sonarr"
        dataDir = "/home/media/.local/state/sonarr/.config/NzbDrone";
      };
      prowlarr = {
        enable = true;
        openFirewall = true; # 9696
      };
      plex = let
        plexpass = pkgs.plex.override {
          plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
            version = "1.41.0.8994-f2c27da23";
            src = pkgs.fetchurl {
              url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
              sha256 = "sha256-e1COeawdR0pCF+qQ/xkTn/716iM9kB/fXom5MWHQ0YI=";
            };
          });
        };
      in {
        package = plexpass;
        enable = false;
        openFirewall = true; # 32400
        user = "media"; # defaults to "plex"
        group = "media"; # defaults to "plex"
        dataDir = "/home/media/.local/state/plex";
        # dataDir = "/home/media/.local/state/plex/.config/Plex Media Server";
        # accelerationDevices = ["*"];
        # extraPlugins = [
        #   (builtins.path {
        #     name = "Audnexus.bundle";
        #     path = pkgs.fetchFromGitHub {
        #       owner = "djdembeck";
        #       repo = "Audnexus.bundle";
        #       rev = "v0.2.8";
        #       sha256 = "sha256-IWOSz3vYL7zhdHan468xNc6C/eQ2C2BukQlaJNLXh7E=";
        #     };
        #   })
        # ];
        # extraScanners = [
        #   (lib.fetchFromGitHub {
        #     owner = "ZeroQI";
        #     repo = "Absolute-Series-Scanner";
        #     rev = "773a39f502a1204b0b0255903cee4ed02c46fde0";
        #     sha256 = "4l+vpiDdC8L/EeJowUgYyB3JPNTZ1sauN8liFAcK+PY=";
        #   })
        # ];
      };
    }; # /services
  }; # /config
}
