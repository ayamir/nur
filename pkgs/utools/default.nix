{ lib
, stdenv
, fetchurl
, makeWrapper
, dpkg
, glib
, nss
, nspr
, atk
, at-spi2-atk
, at-spi2-core
, cups
, dbus
, libdrm
, gtk3
, pango
, cairo
, xorg
, libgbm
, expat
, libxkbcommon
, alsa-lib
, libsecret
, gdk-pixbuf
, mesa
}:

let
  version = "7.5.1";
  runtimeLibs = [
    glib nss nspr atk at-spi2-atk at-spi2-core cups dbus libdrm gtk3
    pango cairo xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libXtst xorg.libxcb libgbm expat
    libxkbcommon alsa-lib libsecret gdk-pixbuf mesa stdenv.cc.cc.lib
  ];
in

stdenv.mkDerivation {
  pname = "utools";
  inherit version;

  src = fetchurl {
    url = "https://open.u-tools.cn/download/utools_${version}_amd64.deb";
    sha256 = "sha256-fjv9EROAKOu9njLBjoRr/effOmnS+BimQewg/wm4Wy0=";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];

  # Do NOT patch the ELF binary — uTools has a CheckForExeIntegrity check
  # (BLAKE3/MD5 in linux-x64.node) that crashes on any modification.
  # nix-ld provides /lib64/ld-linux-x86-64.so.2, so the unpatched binary
  # can run. Libraries are injected via LD_LIBRARY_PATH in the wrapper.
  dontPatchELF = true;
  dontFixup = true;

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/uTools $out/bin $out/share/applications

    cp -r opt/uTools/. $out/opt/uTools/

    for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512 1024x1024; do
      icon="usr/share/icons/hicolor/$size/apps/utools.png"
      if [ -f "$icon" ]; then
        mkdir -p $out/share/icons/hicolor/$size/apps
        cp "$icon" $out/share/icons/hicolor/$size/apps/utools.png
      fi
    done

    makeWrapper $out/opt/uTools/utools $out/bin/utools \
      --add-flags "--no-sandbox" \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath runtimeLibs}"

    cat > $out/share/applications/utools.desktop << EOF
    [Desktop Entry]
    Name=uTools
    Comment=Your next-generation productive tool suite
    Exec=$out/bin/utools %U
    Icon=utools
    Terminal=false
    Type=Application
    Categories=System;
    MimeType=x-scheme-handler/utools;
    StartupWMClass=uTools
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Your next-generation productive tool suite";
    homepage = "https://u.tools";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    mainProgram = "utools";
  };
}
