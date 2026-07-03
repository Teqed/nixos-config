# Repackages Anthropic's official Claude desktop .deb (a self-bundled Electron
# app) for Nix via autoPatchelf. Not in nixpkgs; updated manually.
#
# To bump: the apt Packages index lists every published build. Grab the newest
# version + its SHA256, then convert the hash to SRI:
#   curl -fsSL https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages \
#     | awk '/^Version:/{v=$2} /^SHA256:/{print v" "$2}' | tail -1
#   nix hash convert --hash-algo sha256 --to sri <sha256hex>
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
  glibc,
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
  xdg-utils,
  # bundled virtiofsd (Cowork VM)
  libseccomp,
  libcap_ng,
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
  # Cowork VM helpers (optional)
  withCowork ? true,
  qemu,
}: let
  pname = "claude-desktop";
  version = "1.18286.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-jzFK0agKq1JxGo6qvAaq5I+zQfCt6koNcmTbXKudBTY=";
  };

  # Runtime PATH additions. xdg-utils gives xdg-open for external links;
  # qemu powers the Cowork sandbox VM (the app ships its own virtiofsd + image).
  runtimePath = lib.makeBinPath (
    [xdg-utils]
    ++ lib.optional withCowork qemu
  );
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
      glibc
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

    # The bundled Electron loads these relative to its own directory.
    appendRunpaths = ["${placeholder "out"}/lib/claude-desktop"];

    # dpkg unpacks the .deb; nothing to build.
    # Pipe through tar with --no-same-permissions so the setuid chrome-sandbox
    # (which we delete anyway) doesn't abort extraction inside the build sandbox.
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
      cp -r usr/lib/claude-desktop $out/lib/claude-desktop

      # chrome-sandbox cannot be setuid-root in the Nix store; we rely on the
      # kernel's unprivileged user namespaces instead (see --disable-setuid-sandbox).
      rm -f $out/lib/claude-desktop/chrome-sandbox

      # Desktop entry + icons
      cp -r usr/share/applications $out/share/
      cp -r usr/share/icons $out/share/

      makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
        "''${gappsWrapperArgs[@]}" \
        --prefix PATH : "${runtimePath}" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL mesa]}" \
        --add-flags "--disable-setuid-sandbox" \
        --set-default ELECTRON_FORCE_IS_PACKAGED 1

      runHook postInstall
    '';

    meta = {
      description = "Desktop application for Claude.ai (Chat, Cowork, and Claude Code)";
      homepage = "https://claude.ai";
      license = lib.licenses.unfree;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = ["x86_64-linux"];
      mainProgram = "claude-desktop";
    };
  }
