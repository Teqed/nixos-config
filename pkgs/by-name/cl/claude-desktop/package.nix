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
  libseccomp,
  libcap_ng,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
  libxcb,
  libxshmfence,
  withCowork ? true,
  qemu,
}:
let
  pname = "claude-desktop";
  version = "1.37937.1";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-ZrvGHdBGS1UMTWOBJSARnoNEtGJUHeRHlzUriRiEL08=";
  };

  runtimePath = lib.makeBinPath ([ xdg-utils ] ++ lib.optional withCowork qemu);
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
    libseccomp
    libcap_ng
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

  appendRunpaths = [ "${placeholder "out"}/lib/claude-desktop" ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar -x --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin $out/share
    cp -r usr/lib/claude-desktop $out/lib/claude-desktop

    rm -f $out/lib/claude-desktop/chrome-sandbox

    cp -r usr/share/applications $out/share/
    cp -r usr/share/icons $out/share/
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      "''${gappsWrapperArgs[@]}" \
      --prefix PATH : "${runtimePath}" \
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
      --add-flags "--enable-wayland-ime=true" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1

    runHook postInstall
  '';

  meta = {
    description = "Desktop application for Claude.ai (Chat, Cowork, and Claude Code)";
    homepage = "https://claude.ai";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
