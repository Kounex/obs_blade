#!/bin/bash
# Turns this checkout into the FOSS build (GitHub APK + F-Droid) - see
# docs/foss-build.md. Run from anywhere, before `flutter pub get`:
#
#   tool/foss/prepare.sh              # strip the store SDKs, switch kFoss on
#   tool/foss/prepare.sh verify       # after the build: lockfile + APK check
#   tool/foss/prepare.sh lock         # regenerate pubspec-foss.lock
#   tool/foss/prepare.sh lock --check # fail if pubspec-foss.lock is stale
#
# pubspec-foss.lock is pubspec.lock as pub resolves it without the store
# SDKs. F-Droid builds with `pub get --enforce-lockfile`, so it is
# committed and moved in place here; regenerate it whenever pubspec.yaml or
# pubspec.lock change (the FOSS CI job fails until you do).
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

# The store SDKs out of a pubspec.yaml (and the comment line above
# in_app_purchase)
strip_pubspec() {
  edit "$1" -E \
    -e '/^  # Enable and manage in-app purchases$/d' \
    -e "/^  ($STORE_PACKAGES):/d"
  if grep -qE "^  ($STORE_PACKAGES):" "$1"; then
    fail "$1 still lists a store SDK"
  fi
}

# Resolves the stripped pubspec against pubspec.lock in a scratch dir -
# pub only drops the store packages, every other version stays as locked
lock() {
  local flutter="$REPO_ROOT/.flutter/bin/flutter"
  [ -x "$flutter" ] || flutter="flutter"
  local tmp
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  cp pubspec.yaml pubspec.lock "$tmp/"
  strip_pubspec "$tmp/pubspec.yaml"
  (cd "$tmp" && "$flutter" pub get >/dev/null) ||
    fail "pub get failed for the stripped pubspec"
  if [ "${1:-}" = "--check" ]; then
    if ! diff -u pubspec-foss.lock "$tmp/pubspec.lock"; then
      fail "pubspec-foss.lock is stale - run tool/foss/prepare.sh lock and commit it"
    fi
    echo "foss: pubspec-foss.lock is up to date"
  else
    cp "$tmp/pubspec.lock" pubspec-foss.lock
    echo "foss: wrote pubspec-foss.lock"
  fi
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

case "${1:-}" in
  verify)
    verify "${2:-}"
    exit 0
    ;;
  lock)
    lock "${2:-}"
    exit 0
    ;;
esac

# 1. Dependencies, and the matching lockfile
[ -f pubspec-foss.lock ] || fail "pubspec-foss.lock missing - run tool/foss/prepare.sh lock"
strip_pubspec pubspec.yaml
cp pubspec-foss.lock pubspec.lock

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

echo "foss: tree prepared - next: flutter pub get --enforce-lockfile && flutter build apk"
