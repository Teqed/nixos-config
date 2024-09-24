{
  pkgs,
  lib,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      # Add additional package names here
    ];
  home.packages = with pkgs; [
    source-sans-pro
    source-serif-pro
    source-code-pro
    dejavu_fonts
    (nerdfonts.override {
      fonts = [
        "NerdFontsSymbolsOnly"
        "JetBrainsMono"
      ];
    })
    noto-fonts-lgc-plus
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-monochrome-emoji
    noto-fonts-color-emoji
    liberation_ttf

    bibata-cursors
    papirus-icon-theme
    # ^^ Duplicated from NixOS configuration
    notcurses
    curl
    micro
    wget
    nix-output-monitor
    nil
    kdePackages.kate
    bash-language-server
    bat
    grc
    # atool
    obsidian
    sshfs # programs.sftpman ?
    solaar
    blender-hip # blender with hardware accelerated rendering
    clinfo # For confirming OpenCL support
    ungoogled-chromium # Chrome / Chromium / UngoogledChromium # programs.chromium + extensions
    godot_4-mono
    prismlauncher
    # discord # discocss
    discord-krisp
    vesktop
    lynx
    w3m-nox
    mgba
    handbrake
    python3
    discover-overlay
    most
    plex-media-player
    radeontop
    trash-cli
    zed-editor_git
    rustup # cargo
    catimg
    chafa
    colordiff
    hyperfine
    notcurses
    aseprite
    lan-mouse_git
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
    # Golang-go
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
    bashInteractive # bash with ncurses support
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
    perl
    rsync
    strace
  ];
}
