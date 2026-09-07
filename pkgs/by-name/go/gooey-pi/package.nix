{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  wrapGAppsHook3,
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
  systemd,
  alsa-lib,
  libsecret,
  libnotify,
  libpulseaudio,
  libGL,
  libva,
  xdg-utils,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libxshmfence,
}:
let
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

  appendRunpaths = [ "${placeholder "out"}/lib/gooeypi" ];

  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin $out/share
    cp -r opt/GooeyPi $out/lib/gooeypi

    rm -f $out/lib/gooeypi/chrome-sandbox

    cp -r usr/share/applications $out/share/
    cp -r usr/share/icons $out/share/ 2>/dev/null || true
    substituteInPlace $out/share/applications/gooeypi.desktop \
      --replace-fail "/opt/GooeyPi/gooeypi" "gooeypi"

    makeWrapper $out/lib/gooeypi/gooeypi $out/bin/gooeypi \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          libGL
          mesa
          libva
        ]
      }" \
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
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "gooeypi";
  };
}
