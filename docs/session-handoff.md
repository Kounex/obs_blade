# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-07** (store
products provisioned + priced, Android toolchain migrated, Google package
verification in review; RevenueCat dashboard wiring in progress).

## Handoff hygiene (read before editing this file)

- **This is a baton, not a history log.** It holds only what the *next*
  session needs to pick up work right now — current branch, immediate open
  threads, pointers to the docs with real depth. If you're about to narrate
  *what happened and why*, that belongs in `changelog-agent.md` (history) or
  a dedicated `docs/*.md` (architecture/design/strategy) — leave only a
  pointer here, not the content itself.
- **Clear and rewrite this file at every handoff**, don't accumulate on top
  of the previous version. A stale "still open" note here caused real
  confusion once already: this file kept saying a release blocker was open
  well after it had actually been resolved on the other machine, because
  nobody reset it — they just left the old narrative in place and it quietly
  went stale.
- **`git fetch --all` before trusting anything here or in `AGENTS.md`** —
  diff your branch against its remote counterpart and skim recent log. This
  file is only as current as whoever last updated it remembered to make it.
- **Non-public docs live in `docs/private/`** (gitignored — this repo is
  public; git will never sync it). The sync is **manual, mandatory, and
  same-turn**: after *any* create/edit/delete there, mirror to the other
  machine immediately — no "sync later", that's how the copies silently
  drift — and verify the mirror with checksums. At session start, confirm
  both copies are in sync *before* trusting or editing anything there.
  Exact commands + machine topology: `docs/private/maintainer-workflow.md`
  (maintainer machines only). Don't let state exist on only one machine.

## Workspace facts

| | |
|---|---|
| Remote | `Kounex/obs_blade` (**public**) |
| Branch | **`master`** (includes "On Air" redesign; `redesign` branch retained as history) |
| Users | 500k+ live — persistence + release paths are sensitive |
| Form factors | First-party **phone and tablet** — see `AGENTS.md` + `redesign/design-system.md` § Responsive layouts |

### Machines

The maintainer works from a two-clone setup (headless analyze/test clone +
workstation simulator/device clone). Topology, paths, SDK locations, and
the dogfood handoff rule are maintainer-only and live in
`docs/private/maintainer-workflow.md` (gitignored). Contributors: ignore —
build and test from your own checkout per `AGENTS.md`.

Commit per verified unit proactively (small, logically-scoped commits).
Push when the user asks, and always at wrap-up/handoff — the remote is the
source of truth; never leave work local-only when handing over.

## Right now

**Store products are live (2026-09-07)** — provisioned via
`tool/provisioning/` on both stores with locked pricing **$4.99/mo,
$49.99/yr, $99.99 lifetime**: ASC group "Pro" + `pro_yearly` /
`pro_monthly` / `pro_lifetime` (localized, available in all territories,
prices set); Play subscription `pro` (base plans `pro-yearly` /
`pro-monthly` ACTIVE) + one-time `pro_lifetime` ACTIVE. Console-only
remainder: **product review submission** on both stores (they're not
submitted for review yet — required before they can sell).

**RevenueCat dashboard wiring in progress** — app code is done; follow
[`revenuecat-setup.md`](revenuecat-setup.md) §1–4 (project, store
connections, entitlement `pro` + offering, paste the two public SDK keys
into `lib/utils/revenuecat_config.dart`), then §5 verification
(`test/pro/` + sandbox dogfood). **Attach `pro_lifetime` to the `pro`
entitlement before flipping** or pre-RC lifetime buyers strand.

**Android toolchain migrated to Flutter 3.47 minimums** (2026-09-07):
Gradle 8.14 / AGP 8.11.1 / KGP 2.2.20, `namespace` replaces manifest
`package=`, compile/target SDK follow `flutter.*`. `build appbundle
--release` + `build apk --release` verified on the workstation — the
upgrade-plan "Android not yet built" deferral is cleared *build-wise*;
runtime/device testing is still open. Non-blocking warnings: KGP 2.3.20
recommended; NDK bump to 28.2.13676358 suggested (integration_test).
JDK 17 installed via brew (`openjdk@17`) + `flutter config --jdk-dir` —
machine note added to `private/maintainer-workflow.md`.

**Google developer verification — package registration
`com.kounex.obsBlade` IN REVIEW** (2026-09-07): justification route with
the registered upload key (`A6:24:…`, local `android-release.jks`); the
eligible legacy app-signing key `25:F7:…` is Google-managed and a
Play-signed universal APK failed verification because the signing key was
**upgraded** — SDK 33+ installs are signed by `82:04:…` instead. **After
the review resolves (either way):** delete
`android/app/src/main/assets/adi-registration.properties` (untracked,
holds the one-time registration token) and discard the Play
internal-track draft release `3.3.0 (2026090701)`. Pubspec build number
stays bumped to `2026090701` to avoid versionCode collisions.

**Creds consolidated (2026-09-07):** `~/.config/obs-blade` is now a
symlink → `~/NASync/obs-blade` (Syncthing-backed) holding `asc-key.p8`,
`SubscriptionKey_QJ5A6U8X72.p8`, `play-svc.json`, `youtube-api-key.txt`,
`android-release.jks`/`.pem`; env vars in `~/.localrc`. Provisioning tool
bugs fixed (pagination, ASC subscription availability, price updates) —
suite at 34 tests.

**Immediate next threads:**

1. **Finish RevenueCat** (maintainer, browser): `revenuecat-setup.md`
   §1–4, then hand the public keys to the agent → §5 verify. Also:
   **Apple Small Business Program enrollment** (developer site, cuts
   commission to 15%) was explained; Play's 15%/10% tiers are automatic.
   Then submit ASC + Play products for review.
2. **Dogfood the Pro gate** on the workstation via the debug override
   (long-press paywall hero): gate flip mid-session, legacy persisted
   `SelectedChatEngine=native` boot path, settings row states.
3. **Android runtime smoke** (emulator/device) now that the toolchain
   builds — dashboard + chat basics.
4. YouTube: GCP key exists (`~/.config/obs-blade/youtube-api-key.txt`);
   run the spike (`tool/youtube_spike/`, ≥30 min busy chat, record units
   into `youtube-native-chat-audit.md`). OAuth consent screen + TV client
   stay console-only. The `private/backend-architecture.md` OAuth note is
   **still deferred — sync private docs first**.

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Test gotchas are in
`changelog-agent.md`. `test/pro/` is the purchase/entitlement suite home
(no precedent existed before this wave).

**Cursor note:** visual companion under Cursor needs
`visual-companion-cursor` (foreground `--foreground` start) — bare
Superpowers `start-server.sh` dies when the shell exits.

## Verify quickly

```bash
git checkout master && git pull
flutter test test/chat/ test/websocket/ test/persistence/ test/pro/
```

Maintainer: machine-specific verify, simulator, and visual-QA commands are
in `docs/private/maintainer-workflow.md`.

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
