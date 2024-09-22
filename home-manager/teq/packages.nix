{pkgs, ...}: {
  home.packages = with pkgs; [
    kdePackages.kate
    bash-language-server
    bat
    grc
    # atool
    obsidian
    sshfs # programs.sftpman ?
    solaar
    blender
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
  ];
}
