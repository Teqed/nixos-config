{
  pkgs,
  lib,
  config,
  ...
}:
let
  profile = "media";
in
{
  options.teq.nixos = {
    media = lib.mkEnableOption "Teq's NixOS Media configuration defaults.";
  };
  config = lib.mkIf config.teq.nixos.media {
    services = {
      jellyseerr = {
        enable = false;
        openFirewall = true;
      };
      bazarr = {
        enable = true;
        openFirewall = true;
        user = profile;
        group = profile;
      };
      sabnzbd = {
        enable = false;
        openFirewall = true;
        user = profile;
        group = profile;
        configFile = "/home/media/.local/state/sabnzbd/sabnzbd.ini";
      };
      radarr = {
        enable = true;
        openFirewall = true;
        user = profile;
        group = profile;
        dataDir = "/home/media/.local/state/radarr/.config/Radarr";
      };
      jellyfin = {
        enable = false;
        openFirewall = true;
        user = profile;
        group = profile;
        dataDir = "/home/media/.local/state/jellyfin";
        configDir = "/home/media/.local/state/jellyfin/config";
        logDir = "/home/media/.local/state/jellyfin/log";
        cacheDir = "/home/media/.cache/jellyfin";
      };
      tautulli = {
        enable = true;
        openFirewall = true;
        user = profile;
        group = profile;
        dataDir = "/home/media/.local/state/plexpy";
        port = 8181;
        configFile = "/home/media/.local/state/plexpy/config.ini";
      };
      readarr = {
        enable = true;
        openFirewall = true;
        user = profile;
        group = profile;
        dataDir = "/home/media/.local/state/readarr/.config/Readarr";
      };
      sonarr = {
        enable = true;
        openFirewall = true;
        user = profile;
        group = profile;
        dataDir = "/home/media/.local/state/sonarr/.config/NzbDrone";
      };
      prowlarr = {
        enable = true;
        openFirewall = true;
      };
      plex =
        let
          plexpass = pkgs.plex.override {
            plexRaw = pkgs.plexRaw.overrideAttrs (_: rec {
              version = "1.41.0.8994-f2c27da23";
              src = pkgs.fetchurl {
                url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
                sha256 = "sha256-e1COeawdR0pCF+qQ/xkTn/716iM9kB/fXom5MWHQ0YI=";
              };
            });
          };
        in
        {
          package = plexpass;
          enable = false;
          openFirewall = true;
          user = profile;
          group = profile;
          dataDir = "/home/media/.local/state/plex";
        };
    };
  };
}
