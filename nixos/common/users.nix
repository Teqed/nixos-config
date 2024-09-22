{pkgs, ...}: {
  users.users.teq = {
    isNormalUser = true;
    description = "Teq";
    extraGroups = ["networkmanager" "wheel" "audio" "docker"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICRc7d7TBl5Y43KsLQZgP9ewJSmyAbC2xXDnASIa1T5B teq@thoughtful"
    ];
    packages = with pkgs; [
      kdePackages.kate
      bash-language-server
      bat
      grc
      # atool
      lesspipe
      fastfetch
      obsidian
      sshfs
      obs-studio
      solaar
      blender
      ungoogled-chromium # Chrome / Chromium / UngoogledChromium
      godot_4-mono
      prismlauncher
      # discord
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
      btop
      zed-editor_git
      rustup # cargo
      catimg
      chafa
      colordiff
      fd
      gh # / GitHub Desktop
      hstr
      hyperfine
      jq
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
      # Remnia RDP
      # lutris / lutris-free / lutris-unwrapped
      # Imagemagick
      # nerdfonts # powerline-fonts
      # noto-fonts-color-emoji
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
  };
}
