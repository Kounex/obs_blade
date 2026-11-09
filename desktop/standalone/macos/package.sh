#!/bin/bash
# Makes the standalone's .app distributable: Qt inside (QtCore / QtGui /
# QtWidgets frameworks, the cocoa platform and mac style plugins - nothing
# else is used), signed inside out with the hardened runtime and a secure
# timestamp, packed into a .dmg (app + Applications link). Notarize and
# staple the .dmg afterwards (desktop/notarize.sh).
#
#   package.sh <built .app> <Qt prefix, e.g. plugin/.deps/obs-deps-qt6-*> <out .dmg> [identity]
#
# Without an identity everything is signed ad hoc (local tests only).
set -euo pipefail
app=$1
qt=$2
dmg=$3
identity=${4:--}

name=$(basename "$app")
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/$name"
contents="$stage/$name/Contents"
exe="$contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$contents/Info.plist")"

mkdir -p "$contents/Frameworks" "$contents/PlugIns/platforms" "$contents/PlugIns/styles" "$contents/Resources"
for framework in QtCore QtGui QtWidgets; do
  rsync -a --exclude Headers --exclude '*.prl' "$qt/lib/$framework.framework" "$contents/Frameworks/"
done
cp "$qt/plugins/platforms/libqcocoa.dylib" "$contents/PlugIns/platforms/"
cp "$qt/plugins/styles/libqmacstyle.dylib" "$contents/PlugIns/styles/"
# The plugins look for Qt in ../../lib (obs-deps' layout); here it's ../../Frameworks
for plugin in "$contents"/PlugIns/*/*.dylib; do
  install_name_tool -add_rpath @loader_path/../../Frameworks "$plugin" 2>/dev/null
done
printf '[Paths]\nPlugins = PlugIns\n' > "$contents/Resources/qt.conf"

# The build's absolute rpath to obs-deps out, the bundle's Frameworks in
otool -l "$exe" | awk '/LC_RPATH/ {getline; getline; print $2}' | sort -u | while read -r rpath; do
  [[ $rpath == @* ]] || install_name_tool -delete_rpath "$rpath" "$exe"
done
install_name_tool -add_rpath @executable_path/../Frameworks "$exe" 2>/dev/null || true

sign=(codesign --force --options runtime --sign "$identity")
[[ $identity == - ]] || sign+=(--timestamp)
for plugin in "$contents"/PlugIns/*/*.dylib; do "${sign[@]}" "$plugin"; done
for framework in "$contents"/Frameworks/*.framework; do "${sign[@]}" "$framework/Versions/A"; done
"${sign[@]}" "$stage/$name"
codesign --verify --deep --strict "$stage/$name"
if otool -L "$exe" "$contents"/PlugIns/*/*.dylib | grep -E '^\s+/(Users|opt|usr/local)/'; then
  echo "absolute library paths left (above)" >&2
  exit 1
fi

ln -s /Applications "$stage/Applications"
rm -f "$dmg"
hdiutil create -quiet -volname "${name%.app}" -srcfolder "$stage" -format UDZO -fs HFS+ "$dmg"
[[ $identity == - ]] || codesign --force --timestamp --sign "$identity" "$dmg"
echo "$dmg"
