{pkgs, ...}: {
  security.sudo = {
    enable = true;
    package = pkgs.sudo.override {
      withInsults = true;
    };
    extraConfig = ''
      Defaults lecture = never
    '';
  };
  services = {
    openssh = {
      enable = true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no"; # disable root login
        PasswordAuthentication = false; # disable password login
        StreamLocalBindUnlink = "yes"; # Automatically remove stale sockets
        GatewayPorts = "clientspecified"; # Allow forwarding ports to everywhere
        AcceptEnv = "WAYLAND_DISPLAY"; # Let WAYLAND_DISPLAY be forwarded
      };
      openFirewall = true;
    };
    spice-vdagentd.enable = true;
    earlyoom.enable = true;
    hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
    };
    keyd = {
      # A key remapping daemon for linux. https://github.com/rvaiya/keyd
      enable = true;
      keyboards.default.settings = {
        main = {
          # overloads the capslock key to function as both escape (when tapped) and capslock (when held)
          capslock = "overload(capslock, esc)";
        };
      };
    };
    flatpak = {
      enable = true;
      # packages = [ # system # /var/lib/flatpak
      #   { appId = "com.brave.Browser"; origin = "flathub";  }
      #   "com.obsproject.Studio"
      #   "im.riot.Riot"
      # ];
      update.auto = {
        enable = true;
        onCalendar = "weekly"; # Default value
      };
      overrides = {
        global = {
          Context.sockets = ["wayland" "!x11" "!fallback-x11"]; # Force Wayland by default
          Environment = {
            XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons"; # Fix un-themed cursor in some Wayland apps
            GTK_THEME = "Adwaita:dark"; # Force correct theme for some GTK apps
          };
        };
        "com.visualstudio.code".Context = {
          filesystems = [
            "xdg-config/git:ro" # Expose user Git config
            "/run/current-system/sw/bin:ro" # Expose NixOS managed software
          ];
          sockets = [
            "gpg-agent" # Expose GPG agent
            "pcsc" # Expose smart cards (i.e. YubiKey)
          ];
        };
        "org.onlyoffice.desktopeditors".Context.sockets = ["x11"]; # No Wayland support
      };
    };
    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
    };
    xrdp = {
      enable = true;
      openFirewall = true;
    };
  };
  systemd.services.systemd-udev-settle.enable = false; # don't wait for udev to settle on boot
  systemd.services.NetworkManager-wait-online.enable = false; # don't wait for network to be up on boot
}
