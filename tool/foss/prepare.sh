#!/bin/bash
# Turns this checkout into the FOSS build (GitHub APK + F-Droid) - see
# docs/foss-build.md. Run from anywhere, before `flutter pub get`:
#
#   tool/foss/prepare.sh          # strip the store SDKs, switch kFoss on
#   tool/foss/prepare.sh verify   # after the build: lockfile + APK check
#
# It REWRITES tracked files (pubspec.yaml, lib/...). Use a throwaway
# checkout (CI, F-Droid's build server) or `git checkout . && git clean -fd
# lib` afterwards. F-Droid's recipe runs exactly this, so keep the two in
# step: the CI workflow (.github/workflows/foss-release.yml) builds the
# same way and its APK has to match F-Droid's byte for byte.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

# Store SDKs: both link Google Play Billing (non-free), RevenueCat on top
STORE_PACKAGES='in_app_purchase|purchases_flutter'
# What must not end up in the APK (dex class descriptors)
NONFREE_CLASSES='Lcom/android/billingclient/|Lcom/revenuecat/'

fail() {
  echo "foss: $*" >&2
  exit 1
}

# Portable in-place edit (GNU and BSD sed differ on -i)
edit() {
  local file="$1"
  shift
  sed "$@" "$file" >"$file.foss" && mv "$file.foss" "$file"
}

verify() {
  if grep -qE "^  ($STORE_PACKAGES):" pubspec.lock; then
    fail "pubspec.lock still resolves a store SDK - run prepare before pub get"
  fi
  local apk="${1:-build/app/outputs/flutter-apk/app-release.apk}"
  [ -f "$apk" ] || fail "no APK at $apk"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  unzip -q -o "$apk" 'classes*.dex' -d "$tmp"
  if grep -aqE "$NONFREE_CLASSES" "$tmp"/classes*.dex; then
    fail "$apk contains Play Billing / RevenueCat classes"
  fi
  echo "foss: $apk is free of store SDKs"
}

if [ "${1:-}" = "verify" ]; then
  verify "${2:-}"
  exit 0
fi

# 1. Dependencies (and the comment line above in_app_purchase)
edit pubspec.yaml -E \
  -e '/^  # Enable and manage in-app purchases$/d' \
  -e "/^  ($STORE_PACKAGES):/d"

# 2. kFoss on, without relying on a --dart-define
edit lib/utils/build_flavor.dart \
  -e "s/^const bool kFoss = bool.fromEnvironment('OBS_BLADE_FOSS');$/const bool kFoss = true;/"
grep -q '^const bool kFoss = true;$' lib/utils/build_flavor.dart ||
  fail "couldn't switch kFoss on in lib/utils/build_flavor.dart"

# 3. SDK-free stand-ins for the files importing a store SDK, and the
#    files only those imported
cp -R tool/foss/overlay/lib/. lib/
rm -f \
  lib/utils/revenuecat_pro_gateway.dart \
  lib/views/settings/widgets/support_dialog/tips_content.dart \
  lib/views/settings/widgets/support_dialog/donate_button.dart

# 4. Nothing may import a store SDK any more - a new import on master
#    needs a stand-in here (the FOSS CI job catches it on every push)
if left="$(grep -rlE "package:($STORE_PACKAGES)/" lib)"; then
  fail "still importing a store SDK: $left"
fi
if grep -qE "^  ($STORE_PACKAGES):" pubspec.yaml; then
  fail "pubspec.yaml still lists a store SDK"
fi

echo "foss: tree prepared - next: flutter pub get && flutter build apk"
