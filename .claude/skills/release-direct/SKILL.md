---
name: release-direct
description: Use when the user wants a new OBS Blade version sent straight to the stores without a separate testing round - e.g. "update to 4.0.1 and get it to the stores", "ship this as a hotfix". Runs release-beta and release-promote back to back (the stores need the beta uploads anyway), with one confirmation before submitting. Ends waiting for approval; release-publish makes it live.
---

# Release straight to the stores

Read [`docs/release-playbook.md`](../../../docs/release-playbook.md) first.
Maintainers: `docs/private/maintainer-workflow.md` § "Store releases over SSH".

There is no shortcut past the internal tracks: `submit ios` needs the build
processed on App Store Connect, and Play production is a promotion of the
internal release. "Direct" only means no pause for device testing.

## Steps

1. **`release-beta` steps 1-7** - version, notes (shown to the user), commit
   + push, preflight, build + upload both platforms, verify.
2. **Check what this skips.** No device test of the store build happened.
   Say so; the change set should be small or already verified (tests,
   simulator / dogfood build). For anything larger suggest `release-beta`
   and a test round instead.
3. **`release-promote` steps 1-5** - iOS version + notes, one confirmation
   covering notes and rollout share, submit iOS, promote Android, verify.

## Hand-off

Same as `release-promote`: both stores in review, `release-publish` once
both are approved. Meanwhile the build is on TestFlight / Play internal if
the user wants to try it before it goes live.
