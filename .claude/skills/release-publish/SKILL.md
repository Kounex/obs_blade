---
name: release-publish
description: Use when an OBS Blade version passed App Review / Play review and should go live - e.g. "Apple approved 4.0.1", "publish the release", "both stores approved". Releases the iOS version, walks the user through the Play Console publish, then tags the release and updates the changelog and handoff docs.
---

# Publish an approved release

Read [`docs/release-playbook.md`](../../../docs/release-playbook.md) first.
Maintainers: `docs/private/maintainer-runbooks.md` § "Store releases over SSH".

## Preconditions

- `release status`: the App Store version is `PENDING_DEVELOPER_RELEASE`
  (approved, waiting). Anything else - still in review, rejected - stop and
  tell the user; a rejection needs the reason from App Store Connect.
- Play: the user sees the release as approved under Publishing overview.
  `release status` can't tell managed-publishing state apart - ask.
- Release both together unless the user wants otherwise.

## Steps

1. **iOS.** `release publish ios` (dry run), confirm with the user, `--yes`.
2. **Play.** The user presses **Publish** in the Play Console (Publishing
   overview → changes ready to publish). There's no API for it - ask them
   and wait for the confirmation.
3. **Verify.** `release status`: App Store version `READY_FOR_SALE`, Play
   `production` on the new version, status `completed` (or `inProgress`
   for a staged rollout).
4. **Tag** the release commit (`release: <name> build <build>`) with the
   bare version (`4.0.1`, matching the existing tags) and push the tag.
5. **Docs.** `docs/changelog-agent.md` entry (what shipped, the build,
   rollout, anything odd on the stores). Reset `docs/session-handoff.md`
   per its hygiene rules: the live version on both stores and what to watch
   (crash reports, reviews, a staged rollout to raise).
6. Commit + push.

## Staged rollout follow-up

With Play below 100 %, raise the share in the Play Console (Production →
the release → update rollout). The tool has no command for it - its
`promote` lane always goes internal → production. `release halt android`
stops a bad rollout.
