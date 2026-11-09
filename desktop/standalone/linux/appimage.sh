#!/bin/bash
# Packs the standalone (built against the distribution's Qt6 - build on an
# old distribution, the AppImage needs its glibc or newer) as an AppImage
# with Qt inside (linuxdeploy + its Qt plugin), x86_64.
#
#   appimage.sh <cmake build dir> <out .AppImage>
#
# TOOLS_DIR caches the downloaded tools; QMAKE picks the Qt (default qmake6).
set -euo pipefail
build=$(cd "$1" && pwd)
out=$2
here=$(cd "$(dirname "$0")" && pwd)
tools=${TOOLS_DIR:-$(mktemp -d)}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

fetch() {
  [ -x "$tools/$1" ] || { curl -sSfLo "$tools/$1" "$2"; chmod +x "$tools/$1"; }
}
fetch linuxdeploy-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
fetch linuxdeploy-plugin-qt-x86_64.AppImage https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage
# appimagetool's current runtime is static: the AppImage runs without libfuse2
fetch appimagetool-x86_64.AppImage https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage

export APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 PATH="$tools:$PATH"
export QMAKE=${QMAKE:-$(command -v qmake6 || command -v qmake)}

cp "$here/../resources/app-256.png" "$work/obs-blade-remote.png"
linuxdeploy-x86_64.AppImage --appdir "$work/AppDir" \
  --executable "$build/obs-blade-remote" \
  --desktop-file "$here/obs-blade-remote.desktop" \
  --icon-file "$work/obs-blade-remote.png" \
  --plugin qt
rm -f "$out"
appimagetool-x86_64.AppImage --no-appstream "$work/AppDir" "$out"
echo "$out"
