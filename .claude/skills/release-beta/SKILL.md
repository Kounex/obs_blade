---
name: release-beta
description: Use when the user wants a new OBS Blade version built and sent to testing - TestFlight (internal testers) and the Google Play internal track - e.g. "put 4.1.0 on TestFlight", "new beta build", "push this for testing". Sets the version, writes the release notes, builds both platforms and uploads them. Stops before anything goes to App Review or production.
---

# Release to testing (TestFlight + Play internal)

Read [`docs/release-playbook.md`](../../../docs/release-playbook.md) first -
rules, versioning, notes, where the tool runs. Maintainers also need
`docs/private/maintainer-workflow.md` § "Store releases over SSH".

## Steps

1. **State.** `git fetch`, clean tree on the release branch (`master`),
   `release status` - what's live, in review and on each track.
2. **Version.** Set the name in `pubspec.yaml` (the user's, or per the
   playbook's rules), then `release bump` for the build number.
3. **Notes.** Draft from the commits since the last release tag (playbook §
   Release notes), write both files, show them to the user. Android's copy
   is final once uploaded - get it right now.
4. **Commit + push** `release: <name> build <build>`.
5. **Preflight.** `release preflight` on the build machine (after pulling
   there). Must pass.
6. **Build + upload**, detached with a log (playbook § Rules):
   `release build ios && release beta ios --yes && release build android && release beta android --yes`
   `beta ios` waits until App Store Connect has processed the build.
7. **Verify.** `release status`: the new build `VALID` under App Store
   builds and on the Play `internal` track.

## Hand-off

Tell the user the build is on TestFlight and Play internal, what to test
(the notes are the checklist, plus an upgrade over the store version with
saved connections / settings), and that `release-promote` takes this exact
build to the stores once they're happy. Nothing was submitted for review.
