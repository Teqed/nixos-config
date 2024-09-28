{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.teq.home-manager;
in {
  options.teq.home-manager = {
    packages = lib.mkEnableOption "Teq's Home-Manager Packages configuration defaults.";
  };
  config = lib.mkIf cfg.packages {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        # Add additional package names here
      ];
    home.packages = with pkgs; [
      source-sans-pro # 6MB
      source-serif-pro # 5MB
      source-code-pro # 2MB
      dejavu_fonts # 10MB
      (nerdfonts.override {
        fonts = [
          "NerdFontsSymbolsOnly"
          "JetBrainsMono"
        ];
      })
      noto-fonts-lgc-plus # 11MB
      noto-fonts-cjk-sans # 62MB
      noto-fonts-cjk-serif # 54MB
      noto-fonts-monochrome-emoji # 2MB
      noto-fonts-color-emoji # 10MB
      liberation_ttf # 4MB

      bibata-cursors # 160MB
      papirus-icon-theme # 200MB / 130MB
      # ^^ Duplicated from NixOS configuration

      # Especially large programs:

      # blender-hip # blender with hardware accelerated rendering # 6.2GB / 1 GB
      # godot_4-mono # 2.9GB / 1.3 GB
      # prismlauncher # 2.8GB / 700 MB
      ungoogled-chromium # Chrome / Chromium / UngoogledChromium # programs.chromium + extensions # 2GB / 600 MB
      obsidian # 1.8GB / 20MB
      vesktop # 1.8GB / 8MB
      # ( electron 1.8GB / 400MB )
      plex-media-player # 1.7GB / 300MB
      handbrake # 1.5GB / 64MB (ffmpeg 1.3GB / 35MB)
      kdePackages.kate # 1.4GB / 40MB (ktexteditor)
      # discord # discocss
      discord-krisp # 1.3GB / 300MB (mesa 800MB)
      lan-mouse_git # 900MB / 10MB (libadwaita 900MB)
      mgba # 800MB / 10MB (ffmpeg)
      notcurses # 700MB / 10MB (ffmpeg)
      solaar # 600MB / 30MB (gtk+3 600MB)
      discover-overlay # 600MB / 15MB (gtk+3, gtk-layer-shell)
      bash-language-server # 300MB / 200MB (nodejs 200MB)
      zed-editor_git # 230MB / 160MB
      python3 # 165MB / 108MB (gcc 40MB, openssl 40MB, readline 40MB, ncurses 30MB, sqlite 30MB, bash 30MB, etc.)
      aseprite # 117MB / 20MB (harfbuzz 70MB / 3MB)

      # ;
      curl # 55MB / 200KB (openssl)
      micro
      wget
      nix-output-monitor
      nix-tree
      nil
      nixd # Nix language server, based on nix libraries https://github.com/nix-community/nixd
      grc
      # atool
      sshfs # programs.sftpman ?
      clinfo # For confirming OpenCL support
      lynx
      w3m-nox
      most
      radeontop
      trash-cli
      rustup # cargo
      catimg
      chafa
      colordiff
      hyperfine
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
      # Golang-go # exists
      # Lua
      # Wine
      #  wget
      #       xdg-desktop-portal-gtk # must be installed for GTK/GNOME applications to correctly apply cursor themeing on Wayland.
      # busybox_appletless

      # The following packages are included by default by Nix's system-path at /run/current-system/sw. We'll declare them below to be explicit.
      # The set of packages that appear in /run/current-system/sw.  These packages are automatically available to all users, and are automatically
      # updated every time you rebuild the system configuration.  (The latter is the main difference with installing them in the default profile, {file}`/nix/var/nix/profiles/default`.

      # requiredPackages = map (pkg: lib.setPrio ((pkg.meta.priority or lib.meta.defaultPriority) + 3) pkg)
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
    ];
  };
}
