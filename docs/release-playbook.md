# Release playbook

Shared baseline for every store release. The project skills
(`.claude/skills/release-*`) are the entry points and read this first:

| Skill | Use when |
|---|---|
| `release-beta` | New version to TestFlight + Play internal for device testing |
| `release-promote` | A tested beta build goes to App Review + Play production |
| `release-direct` | Both of the above in one go, no pause for device testing |
| `release-publish` | Both stores approved - make it live, tag, write it up |

The tool itself is documented in [`tool/release/README.md`](../tool/release/README.md);
this file is the process around it.

## Where it runs

`tool/release` needs macOS with Xcode, Flutter, the repo's Ruby/bundler
(fastlane) and the store credentials (env vars, see the tool README). Build
and upload on that machine. **Maintainers:** the machine, SSH access,
environment and keychain recipe are in
`docs/private/maintainer-runbooks.md` § "Store releases over SSH".

`release <cmd>` below means `dart run tool/release/bin/release.dart <cmd>`
from the repo root.

## Rules for every release

- **Dry run first.** Every store-writing command (`beta`, `metadata`,
  `preview`, `submit`, `publish`, `promote`, `halt`) prints its plan and
  stops without `--yes`. Read the plan, then re-run with `--yes`.
- **Preflight gates the build** (`release preflight`): clean tree, HEAD
  pushed, build number newer than both stores, notes present, credentials.
  Fix what it reports - never work around it.
- **Ask the user before** `submit ios`, `promote android` and
  `publish ios`, showing the release notes and the rollout share. Internal
  uploads (`beta`) run without asking once the user asked for the release.
- **Long runs** (builds, uploads) run detached on the build machine with a
  log file, so a dropped SSH session doesn't kill them - poll the log.
- **Commit per step** (`release: <version> build <n>`), push before
  building - preflight refuses unpushed HEADs.

## Version

`pubspec.yaml` `version: <name>+<build>`.

- **Name** (edit by hand): patch `x.y.Z` for fixes, minor `x.Y.0` for
  features, major `X.0.0` for redesigns / breaking changes. The user may
  give it outright ("make it 4.0.1").
- **Build** `YYYYMMDDNN`: `release bump` sets the next one (today + counter).
  Same number on both stores; it must be newer than anything either store
  has seen, including abandoned uploads.

## Release notes

One text for both stores:
`fastlane/metadata/ios/en-US/release_notes.txt` and
`fastlane/metadata/android/en-US/changelogs/default.txt` (copy, keep them
identical).

- **Source:** `git log <last release tag>..HEAD -- lib android ios assets
  pubspec.yaml` (tags are the bare version, e.g. `4.0.0`), plus the matching
  `docs/changelog-agent.md` entries for the why.
- **Write for users:** what they notice, not how it was fixed. Short
  bullets, no internal names, no issue numbers. Keep the existing voice: a
  one-line opener, bullets, a closing line pointing to GitHub feedback.
- **Limits:** Play what's new ≤ 500 characters (preflight counts). The
  Play notes go up with `beta android` - Play won't take the same
  versionCode twice, so after that they can only be changed in the Play
  Console. The iOS notes are set by `metadata ios` and lock once
  `submit ios` sent the version to review.
- **TestFlight "What to Test"** comes from `fastlane/testflight_notes.txt`
  when it exists (falls back to the iOS release notes): a tester checklist
  for the beta - what's new and what to try, internal names allowed, no
  length limit worth worrying about (4,000). Rewrite it for every beta -
  a stale one ships with the next build. It never reaches the App Store
  listing.
- Show the notes to the user before the first upload.

## Stores, briefly

- **iOS** releases are manual: `submit ios` sends the version (plus any
  first-time subscriptions) to App Review; after approval it sits at
  Pending Developer Release until `publish ios`.
- **Play** uses managed publishing: `promote android` moves the internal
  release to production and sends it to review; after approval nothing goes
  live until the user presses **Publish** in the Play Console (Publishing
  overview). There is no API for that step.
- `release status` shows both stores at any point.
- `metadata ios` also re-uploads the committed screenshot set
  (`fastlane/screenshots`). App Previews are not part of it - check the new
  version still has one (ASC copies media into a new version) and use
  `release preview ios` if not.
- Creative assets (iOS 27+ product page header + search results) live in
  the Asset Library, independent of versions: `release assets ios` uploads
  `fastlane/assets/ios/universal.png` and submits it standalone for
  review, `release attach ios` places the approved asset on the live
  version (publishes immediately, no new version). Approved assets can be
  swapped at any time without another review.

## Rollout

Play defaults to 100 % (`--rollout 1.0`). For feature releases prefer a
staged rollout (`--rollout 0.2`) and raise it once crash reports stay
quiet; `release halt android` stops a bad one. The tool doesn't set up a
phased release on iOS - `publish ios` releases to everyone.

## After publishing

Tag the release commit with the bare version and push the tag, add a
`docs/changelog-agent.md` entry, reset `docs/session-handoff.md`
(release state + what to watch). Details in the `release-publish` skill.
