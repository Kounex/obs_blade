# FOSS build (GitHub APK + F-Droid)

The open source build is master with the store SDKs stripped and Pro left
out. No separate branch: the old `foss` branch (3.2.0, 2023) fell 1,150
commits behind because a strip commit can't be rebased onto every
release. It's kept only as history.

## What's different from the store build

`kFoss` (`lib/utils/build_flavor.dart`) is `true`:

| | Store build | FOSS build |
|---|---|---|
| Store SDKs | `in_app_purchase` + `purchases_flutter` (Play Billing, RevenueCat) | removed from `pubspec.yaml` |
| `ProStore.isPro` | entitlement | always `false`, no backend init |
| Chat | WebView + native engines, Combined | WebView only (`nativeChatAvailableFor` false, no Combined in the type picker) |
| Chat tab | Chat \| Activity (side by side on tablets with Pro) | the chat alone |
| Activity feed, chat TTS | Pro | not shown (their gates are `isPro`) |
| Settings | OBS Blade Pro, Custom Theme, Tip Jar (IAP tips) | Tip Jar opens Buy Me a Coffee; Pro + Custom Theme rows hidden |
| FAQ | WebView/Native answer + "What does Pro unlock?" | WebView answer only |

Pro is left out, not locked: there is nothing to buy, so no upsell either.
Every other Pro surface already hides when `isPro` is false.

## How the strip works

`tool/foss/prepare.sh` rewrites the checkout (CI and F-Droid run it on a
throwaway tree):

1. drops `in_app_purchase` and `purchases_flutter` from `pubspec.yaml`
2. turns `kFoss` into a plain `true` (no `--dart-define` to forget)
3. copies `tool/foss/overlay/lib/**` over `lib/`: SDK-free stand-ins for
   `purchase_base.dart`, `utils/pro_purchase_service.dart` and the Tip Jar
   dialog, with the same names so the shared code compiles unchanged
4. deletes `revenuecat_pro_gateway.dart` and the IAP tip widgets
5. fails if anything in `lib/` still imports a store SDK

`tool/foss/prepare.sh verify` (after the build) fails if `pubspec.lock`
still resolves a store SDK or the APK's dex holds Play Billing /
RevenueCat classes.

**When master adds a store-SDK import**, the `foss` job in
`.github/workflows/flutter-analyze.yml` fails: give the file a stand-in in
`tool/foss/overlay/` (or delete it in `prepare.sh` if nothing else
imports it).

**Tests:** the FOSS UI runs on the regular tree with the define:

```bash
dart tool/test_gate.dart --dart-define=OBS_BLADE_FOSS=true test/foss/
```

Without the define those tests skip.

## Releasing

1. The version is master's `pubspec.yaml` version (same as the stores).
2. Write `fastlane/metadata/android/en-US/changelogs/<versionCode>.txt`
   (F-Droid's "What's new" and the GitHub release notes, max 500 chars;
   no Pro features).
3. Tag and push: `git tag foss-<version> && git push origin foss-<version>`.
4. `.github/workflows/foss-release.yml` builds, verifies and publishes the
   GitHub release `foss-<version>` with `obs-blade-foss-<version>.apk`.
5. F-Droid's checkupdates picks the `foss-*` tag up on its own, builds it
   from source and publishes our APK if the builds match.

A manual run of the workflow (Actions → FOSS release → Run) builds and
verifies without releasing; the APK is a workflow artifact.

## Listing (fastlane metadata)

- `fastlane/metadata/android/` = the **F-Droid** listing (fdroidserver
  reads exactly this path from the tagged commit; verified in
  `fdroidserver/update.py` `insert_localized_app_metadata`). Screenshots
  there show only what the FOSS build has.
- `fastlane/metadata/play/` = the Play listing (`release.yaml`
  `android.metadata`).

fdroidserver **merges** screenshots from every metadata location by file
name, so an override can't remove a Pro screenshot - keep Pro images out
of `fastlane/metadata/android/` entirely.

## Signing

The FOSS APK has its own key (not the Play upload key). Secrets in the
repo's Actions settings: `FOSS_KEYSTORE_BASE64`, `FOSS_KEYSTORE_PASSWORD`,
`FOSS_KEY_ALIAS`, `FOSS_KEY_PASSWORD`. Maintainer backup location:
`docs/private/maintainer-runbooks.md`.

F-Droid only accepts APKs signed with the key in `AllowedAPKSigningKeys`,
and Android only updates an app with the same key. **Losing this key
means every FOSS user has to uninstall and reinstall.** That happened once:
3.2.0 was signed by the CI runner's throwaway debug key
(`CN=Android Debug`, SHA-256 `9183c56b…`), which no longer exists, so
4.2.0 users coming from 3.2.0 have to reinstall.

## Reproducible build layout

F-Droid ships our APK only if its own build matches. Both builds must use
the same:

- **path:** source at `/tmp/build`, `PUB_CACHE=/tmp/build/.pub-cache`
- **Flutter:** the `.flutter` submodule (bump it together with the
  maintainer machines' SDK; the recipe needs no edit)
- **JDK 17**, NDK `27.0.12077973` (pinned in `android/app/build.gradle`)
- **no dependency metadata** in the APK (`dependenciesInfo` in
  `android/app/build.gradle`)

## F-Droid recipe

`metadata/com.kounex.obsBlade.yml` in
[fdroiddata](https://gitlab.com/fdroid/fdroiddata), updated by a merge
request. Draft for 4.2.0 (keep the 3.2.0 build entry above it;
`AllowedAPKSigningKeys` is the FOSS key's certificate):

```yaml
Donate: https://www.buymeacoffee.com/Kounex

Builds:
  - versionName: 4.2.0
    versionCode: 2026102003
    commit: foss-4.2.0
    submodules: true
    sudo:
      - apt-get update
      - apt-get install -y openjdk-17-jdk-headless
      - update-alternatives --auto java
    output: build/app/outputs/flutter-apk/app-release.apk
    rm:
      - ios
      - linux
      - macos
      - web
      - windows
    prebuild:
      - cd ..
      - mv com.kounex.obsBlade /tmp/build
      - pushd /tmp/build
      - export PUB_CACHE=$(pwd)/.pub-cache
      - tool/foss/prepare.sh
      - .flutter/bin/flutter config --no-analytics
      - .flutter/bin/flutter pub get
      - popd
      - mv /tmp/build com.kounex.obsBlade
    scanignore:
      - .flutter/packages/flutter_tools/gradle
      - .flutter/bin/cache
    scandelete:
      - .flutter
      - .pub-cache
    ndk: 27.0.12077973
    build:
      - cd ..
      - mv com.kounex.obsBlade /tmp/build
      - pushd /tmp/build
      - export PUB_CACHE=$(pwd)/.pub-cache
      - .flutter/bin/flutter build apk --release
      - popd
      - mv /tmp/build com.kounex.obsBlade

AllowedAPKSigningKeys: dacd5fe5e0e07a61ead879829101c36d664e56c5af269f6e9789e102c64a4c19

AutoUpdateMode: Version
UpdateCheckMode: Tags ^foss-
UpdateCheckData: pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+
CurrentVersion: 4.2.0
CurrentVersionCode: 2026102003
```

Changes from the 3.2.0 recipe: `tool/foss/prepare.sh` in prebuild, no
`build_runner` (generated code is committed), JDK 17 + NDK pinned,
`Donate`, the new signing key. The merge request should say that the
key changed (old key lost, see Signing) so reviewers expect the
signature switch.
