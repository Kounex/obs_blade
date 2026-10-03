---
name: release-promote
description: Use when an OBS Blade build already on TestFlight / the Play internal track has been tested and should go to the stores - e.g. "the beta is good, release it", "promote 4.1.0", "submit the TestFlight build". Submits the iOS version to App Review and promotes the Play internal release to production review. Ends waiting for approval; release-publish makes it live.
---

# Promote a tested build to the stores

Read [`docs/release-playbook.md`](../../../docs/release-playbook.md) first.
Maintainers: `docs/private/maintainer-workflow.md` § "Store releases over SSH".

## Preconditions - check, don't assume

- `release status`: the build in `pubspec.yaml` (`<name>+<build>`) is
  `VALID` under App Store builds **and** is what the Play `internal` track
  holds. If `pubspec.yaml` moved on since the beta, stop - promote the build
  that was tested or make a new beta (`release-beta`).
- `git log <release commit>..HEAD -- lib android ios assets pubspec.yaml`
  is empty, or the user knows those changes are not in this build.
- The user confirmed the build tested fine.

## Steps

1. **iOS version + notes.** `release metadata ios` (dry run), then `--yes`:
   creates the App Store version `<name>` with the notes and screenshots.
   Check the version still has its App Preview (playbook § Stores).
   If the Play listing changed since the last release
   (`git diff <last tag> -- fastlane/metadata/android`, the changelogs
   aside), also `release metadata android` - managed publishing holds the
   listing until the user publishes, same as the release.
2. **Confirm with the user:** notes (they lock on submit) and the Play
   rollout share (playbook § Rollout).
3. **Submit iOS.** `release submit ios` (dry run), then `--yes`.
4. **Promote Android.** `release promote android [--rollout <share>]`
   (dry run), then `--yes`.
5. **Verify.** `release status`: App Store version `WAITING_FOR_REVIEW`,
   Play production shows the new version.

## Hand-off

Both stores are in review. iOS waits at Pending Developer Release after
approval, Play holds it under managed publishing. When both are approved:
`release-publish`.
