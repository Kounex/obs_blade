# release

Store release tool for OBS Blade: status, preflight checks, store builds,
and the uploads to TestFlight / Google Play through fastlane
(`fastlane/Fastfile`).

```bash
# macOS with Xcode, Flutter, Ruby (bundle install once at the repo root)
cd tool/release && dart pub get && cd ../..
dart run tool/release/bin/release.dart status
```

| Command | What it does |
|---|---|
| `status` | What's live, in review and on each track, on both stores |
| `preflight [ios\|android]` | All checks, no build (see below) |
| `bump` | Next build number (`YYYYMMDDNN`) in `pubspec.yaml` |
| `build ios\|android` | Preflight, then the store build (`.ipa` / `.aab`) with the store defines |
| `beta ios\|android` | TestFlight (internal testers) / Play internal track |
| `metadata ios\|android` | Listing text + screenshots from `fastlane/metadata` and `fastlane/screenshots` |
| `preview ios <file.mp4> [--poster 5]` | en-US iPhone App Preview (6.9" slot) of the current version, via the App Store Connect API (fastlane can't); old previews are removed only once the new one is processed |
| `submit ios` | Attaches the uploaded build (manual release) and submits it with any first-time subscriptions in one review submission (App Store Connect API); once approved it waits for `publish ios` |
| `publish ios` | Releases the approved version to the App Store (only when it is Pending Developer Release) |
| `promote android [--rollout 1.0]` | Play internal → production, at the given share of users |
| `halt android` | Halts the Play production rollout |

**Every command that writes to a store** (`beta`, `metadata`, `preview`, `submit`, `publish`,
`promote`, `halt`) prints what it would do and stops. Add `--yes` to do it.

fastlane needs the Ruby whose bundler matches `Gemfile.lock` (not macOS's
system Ruby 2.6). A non-interactive SSH shell may not have it on `PATH` -
put it first (e.g. Homebrew's `/opt/homebrew/opt/ruby/bin` plus its gem
`bin`) when `bundle` complains about a missing bundler or fastlane.

## Preflight

- working tree clean and HEAD pushed
- the build number is newer than anything on the store (`bump` when not)
- iOS: export compliance declared in `Info.plist`, release notes present
- Android: upload key configured, what's new present and ≤ 500 chars
- credentials set, fastlane installed, the app's Kick OAuth client present

Store builds never get `PRO_RELEASE_TEST_UNLOCK` (the dogfood-only Pro
unlock). `beta` refuses an artifact that doesn't match the current version,
or when anything that goes into the binary changed since it was built
(commits touching only `docs/`, Markdown, `fastlane/` or `tool/` are fine).

## Credentials

By path from the environment, same variables as `tool/provisioning`
(walkthrough: `tool/provisioning/CREDENTIALS.md`). Nothing goes into the repo.

| Variable | For |
|---|---|
| `OBS_BLADE_ASC_KEY_PATH`, `_KEY_ID`, `_ISSUER_ID`, `_APP_ID` | App Store Connect API key (role App Manager or higher) |
| `OBS_BLADE_GOOGLE_APPLICATION_CREDENTIALS` | Play service account JSON (app permission: release to production) |
| `RELEASE_KEYCHAIN_PASSWORD_FILE` (optional) | unlocks the login keychain for signing over SSH |

iOS signing is automatic (`ExportOptions.plist`): Xcode creates the
distribution certificate and profile when needed. Android signs with
`android/key.properties`.

App Review contact details live in `fastlane/metadata/ios/review_information/`,
which is gitignored - keep it on the machine that submits.

## A release

The process around these commands (versioning, release notes, when to ask,
tags) is [`docs/release-playbook.md`](../../docs/release-playbook.md).

```bash
release bump && git commit -am "release: 4.0.0 build" && git push
release build ios && release beta ios --yes          # TestFlight
release build android && release beta android --yes  # Play internal
# ... test on devices, including an upgrade over the store version ...
release metadata ios --yes && release metadata android --yes
release preview ios <store-shots out/video/appstore-iphone/appstore-iphone.mp4> --yes
release submit ios --yes
release promote android --yes     # managed publishing holds it after review
# ... both approved ...
release publish ios --yes         # + Play Console: Publishing overview > Publish
```
