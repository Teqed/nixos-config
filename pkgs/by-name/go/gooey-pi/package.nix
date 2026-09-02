# Repackages GooeyPi's official .deb (electron-builder bundle) for Nix via
# autoPatchelf, same pattern as claude-desktop. Not in nixpkgs.
#
# To bump: check https://github.com/am-will/gooey-pi/releases for the newest
# version, then:
#   nix store prefetch-file https://github.com/am-will/gooey-pi/releases/download/v<V>/GooeyPi-<V>-linux-amd64.deb
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
  # runtime libs (Electron / Chromium)
  glib,
  nss,
  nspr,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cups,
  dbus,
  gtk3,
  pango,
  cairo,
  expat,
  libxkbcommon,
  libdrm,
  mesa,
  systemd, # libudev
  alsa-lib,
  libsecret,
  libnotify,
  libpulseaudio,
  libGL,
  libva,
  xdg-utils,
  # X libs
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libxshmfence,
}: let
  pname = "gooey-pi";
  version = "1.1.15";

  src = fetchurl {
    url = "https://github.com/am-will/gooey-pi/releases/download/v${version}/GooeyPi-${version}-linux-amd64.deb";
    hash = "sha256-lUawZvXhgoU1HZY57tyrFHDsUuXFvA0HDJNaZAFgIao=";
  };
in
  stdenv.mkDerivation {
    inherit pname version src;

    nativeBuildInputs = [
      autoPatchelfHook
      dpkg
      makeWrapper
      wrapGAppsHook3
    ];

    buildInputs = [
      glib
      nss
      nspr
      atk
      at-spi2-atk
      at-spi2-core
      cups
      dbus
      gtk3
      pango
      cairo
      expat
      libxkbcommon
      libdrm
      mesa
      systemd
      alsa-lib
      libsecret
      libnotify
      libpulseaudio
      libGL
      libva
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxtst
      libxcb
      libxshmfence
    ];

    # The bundled Electron loads these relative to its own directory.
    appendRunpaths = ["${placeholder "out"}/lib/gooeypi"];

    # zeromq ships both glibc and musl prebuilds; the musl one is never loaded here.
    autoPatchelfIgnoreMissingDeps = ["libc.musl-x86_64.so.1"];

    # dpkg unpacks the .deb; nothing to build. --no-same-permissions so the
    # setuid chrome-sandbox (deleted anyway) doesn't abort extraction.
    unpackPhase = ''
      runHook preUnpack
      dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-permissions --no-same-owner
      runHook postUnpack
    '';

    # Don't let wrapGAppsHook auto-wrap; we add our own flags in one wrapper.
    dontWrapGApps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib $out/bin $out/share
      cp -r opt/GooeyPi $out/lib/gooeypi

      # chrome-sandbox cannot be setuid-root in the Nix store; rely on
      # unprivileged user namespaces instead (see --disable-setuid-sandbox).
      rm -f $out/lib/gooeypi/chrome-sandbox

      # Desktop entry + icons; point Exec at the wrapper on PATH.
      cp -r usr/share/applications $out/share/
      cp -r usr/share/icons $out/share/ 2>/dev/null || true
      substituteInPlace $out/share/applications/gooeypi.desktop \
        --replace-fail "/opt/GooeyPi/gooeypi" "gooeypi"

      makeWrapper $out/lib/gooeypi/gooeypi $out/bin/gooeypi \
        "''${gappsWrapperArgs[@]}" \
        --prefix PATH : "${lib.makeBinPath [xdg-utils]}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL mesa libva]}" \
        --add-flags "--disable-setuid-sandbox" \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--enable-wayland-ime=true"

      runHook postInstall
    '';

    meta = {
      description = "Desktop workspace for Pi, OMP, and Prime Agent coding harnesses";
      homepage = "https://github.com/am-will/gooey-pi";
      license = lib.licenses.mit;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = ["x86_64-linux"];
      mainProgram = "gooeypi";
    };
  }
