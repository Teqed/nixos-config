{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.teq.home-manager.enable {
    systemd.user.startServices = lib.mkDefault "sd-switch"; # Nicely reload system units when changing configs
    services = {
      # remmina.enable = true; # 900MB / 15MB (freerdp 700MB, spice-gtk 600MB)
    };
    programs = {
      # thunderbird.enable = true; # profiles needs to be set
    };
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        # TODO: Move all unfree packages here
      ];
    home.packages = with pkgs; [
      # Especially large programs:
      # blender-hip # blender with hardware accelerated rendering # 6.2GB / 1 GB
      # godot_4-mono # 2.9GB / 1.3 GB
      # prismlauncher # 2.8GB / 700 MB
      # ( electron 1.8GB / 400MB )

      # ;
      # atool
      #
      # flatseal
      # build-essential
      # G++
      # Krita, Gimp
      # Qbittorrent
      # LibreOffice
      # FFMPEG ?
      # Gpick ? Color Picker
      # Cmake
      # Signal Desktop
      # Clang
      # VNC Server
      # lutris / lutris-free / lutris-unwrapped
      # Imagemagick
      # VisualVM
      # Homestuck Collection
      # Ash
      # Autoconf
      # Lua
      # Wine
      #  wget
      #       xdg-desktop-portal-gtk # must be installed for GTK/GNOME applications to correctly apply cursor themeing on Wayland.
      # busybox_appletless

      # The following packages are included by default by Nix's system-path at /run/current-system/sw. We'll declare them below to be explicit.
      acl
      attr
      # bashInteractive # bash with ncurses support
      bzip2
      coreutils-full
      cpio
      curl
      diffutils
      findutils
      gawk
      stdenv.cc.libc
      getent
      getconf
      gnugrep
      gnupatch
      gnused
      gnutar
      gzip
      xz
      less
      libcap
      ncurses
      netcat
      mkpasswd
      procps
      su
      time
      util-linux
      which
      zstd

      # defaultPackageNames =
      perl # 100MB / 55MB
      rsync
      strace

      teams-for-linux
    ];
  };
}
