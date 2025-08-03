{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkDefault;
in {
  config = lib.mkIf config.teq.nixos.enable {
    services.envfs = {
      enable = mkDefault true; # Fuse filesystem that returns symlinks to executables based on the PATH of the requesting process. This is useful to execute shebangs on NixOS that assume hard coded locations in locations like /bin or /usr/bin etc.
      extraFallbackPathCommands = mkDefault ''
        ln -s ${lib.getExe pkgs.bash} $out/bash
        ln -s ${lib.getExe pkgs.zsh} $out/zsh
        ln -s ${lib.getExe pkgs.fish} $out/fish
        ln -s ${lib.getExe pkgs.xonsh} $out/xonsh
      '';
    };
    programs.nix-ld.enable = mkDefault true;

    programs.nix-ld.libraries = with pkgs;
      [
        # Libraries to include on headless systems:
        acl
        attr # required by coreutils stuff to run correctly
        bzip2
        curl
        dbus # screeps
        expat # mesa dep
        fontconfig # screeps
        freetype # screeps
        fuse
        fuse3
        icu # dotnet runtime, e.g. Stardew Valley
        libnotify
        libsodium
        libssh
        libunwind # Godot Engine
        libusb1
        libuuid # Prison Architect
        nspr
        nss
        stdenv.cc.cc # Godot + Blender
        openssl
        openssl_1_1
        # webkitgtk
        glib-networking
        util-linux
        zlib # screeps
        zstd
        libz
      ]
      ++ lib.optionals (config.hardware.graphics.enable) [
        # Only loaded on systems with graphics enabled:
        pipewire
        cups
        libxkbcommon # paradox launcher
        pango # steamwebhelper

        # dependencies for mesa drivers, needed inside pressure-vessel
        mesa
        mesa.llvmPackages.llvm.lib
        vulkan-loader
        wayland
        egl-wayland # egl?
        wayland-utils # utils?
        xorg.libxcb
        xorg.libXdamage
        xorg.libxshmfence
        xorg.libXxf86vm
        libelf
        (lib.getLib elfutils) # elfutils

        libdrm
        libglvnd
        libpulseaudio

        # screeps dependencies
        atk
        cairo
        gdk-pixbuf

        alsa-lib # Prison Architect
        at-spi2-atk
        at-spi2-core # CrossCode
        glib
        gtk2
        gtk3 # screeps
        libGL # Required by steam with proper errors
        libappindicator-gtk2
        libappindicator-gtk3
        xorg.libX11 # Required by steam with proper errors
        xorg.libXScrnSaver # Dead Cells
        xorg.libXcomposite # Required by steam with proper errors
        xorg.libXcursor
        xorg.libXdamage
        xorg.libXext # Required by steam with proper errors
        xorg.libXfixes # Required by steam with proper errors
        xorg.libXi
        xorg.libXrandr # Required by steam with proper errors
        xorg.libXrender
        xorg.libXtst # Required by steam with proper errors
        xorg.libxcb
        xorg.libxkbfile
        xorg.libxshmfence
        xorg.libXinerama
        xorg.libSM
        xorg.libICE
        xorg.libXt
        xorg.libXmu

        # Questionably graphical

        lsb-release # Needed for operating system detection until https://github.com/ValveSoftware/steam-for-linux/issues/5909 is resolved
        pciutils # Errors in output without those
        glibc_multi.bin # run.sh wants ldconfig     # ??????
        # Games' dependencies
        xorg.xrandr
        which
        perl # Needed by gdialog, including in the steam-runtime
        # Open URLs
        xdg-utils
        iana-etc
        python3 # Steam Play / Proton
        xdg-user-dirs # It tries to execute xdg-user-dir and spams the log with command not founds
        sqlite # electron based launchers need newer versions of these libraries than what runtime provides
        libdecor # Blender

        # Others
        libva # Required by steam with proper errors
        libva-utils
        #pipewire.lib
        ocamlPackages.alsa
        harfbuzz # steamwebhelper
        libthai # steamwebhelper
        brotli
        libxml2
        pulseaudio
        systemd
        x264
        libplist

        lsof # friends options won't display "Launch Game" without it
        file # called by steam's setup.sh

        # Without these it silently fails
        gnome2.GConf
        curlWithGnuTls
        libcap
        SDL2
        dbus-glib
        gsettings-desktop-schemas
        ffmpeg
        libudev0-shim

        # Verified games requirements
        libogg
        libvorbis # Dead Cells
        SDL
        SDL2_image
        glew110
        libidn
        tbb

        # Other things from runtime
        flac
        freeglut
        libjpeg
        libpng
        libpng12
        libsamplerate
        libmikmod
        libtheora
        libtiff
        pixman
        speex
        SDL_image
        # SDL_ttf
        SDL_mixer
        SDL2_ttf
        SDL2_mixer
        libdbusmenu-gtk2
        libindicator-gtk2
        libcaca
        libcanberra
        libgcrypt
        libvpx
        librsvg
        xorg.libXft
        libvdpau

        # Prison Architect
        libGLU
        libbsd

        # Loop Hero
        libidn2
        libpsl
        nghttp2.lib
        rtmpdump

        # SteamVR
        procps
        usbutils
        udev

        # Not formally in runtime but needed by some games
        gst_all_1.gstreamer
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-plugins-base
        json-glib # paradox launcher (Stellaris)
        libxcrypt # Alien Isolation, XCOM 2, Company of Heroes 2
        mono
        xorg.xkeyboardconfig
        xorg.libpciaccess
      ];
  };
}
