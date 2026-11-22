# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-11-16** (4.3.0
released).

**Live:** 4.3.0 (build 2026111304, tag `4.3.0` on `279887d8`) on both
stores since 2026-11-16 (App Store `READY_FOR_SALE`, Play production
100 %). FOSS `foss-4.3.0` (`3bd0cefc`, the lockfile fix after the release
commit) is Latest on GitHub Releases. Branch `master`. Releases run through
**store-release** (`release.yaml`); `release metadata ios` does not create
App Store versions (one `POST v1/appStoreVersions` via the tool's
`HttpApiClient`, as for 4.2.0 / 4.3.0). The MacBook is reachable away from
home: `ssh macbook` from the NAS falls back to Tailscale (it-env
`docs/machines/macbook.md`).

**Unreleased on master (next app version, not worth a 4.3.1 alone):**
`f8534538` quick retries after a relay restart (changelog 2026-11-15);
`615b25df` pairing wait hint after 5 s (changelog 2026-11-20) - **not on
the dogfood device yet** (MacBook unreachable over Tailscale 2026-11-20),
device check list in that entry; Start OBS wait that survives the app
being hidden (changelog 2026-11-22, device check list there) - not on the
dogfood device either.

**Watch (4.3.0 = first public remote access):** crash reports + reviews;
relay traffic (`tool/remote_relay/relay-report.sh`; NAS timer
`relay-report-2026-11-27` pushes it at 13:00). First external bridge
since 11-20: 5 connects, all "OBS not running", no relay session yet -
relay 0.0.14's new lines say whether Start OBS works for it and whether
its 4901s come with the bridge reporting OBS running (then the
standalone's process check misses that OBS - fixed in obs-blade-remote
0.4.2, released 2026-11-22: a bridge trusts its live OBS connection; the
count only fires for bridges on 0.4.1 or older, so that user needs the
update; a 0.4.2 bridge logs "OBS answers on its WebSocket, but its process
wasn't found" instead). The 30-100
reconnects a day are the maintainer's MacBook (likely sleep wakes), not the PC;
keepalive timeouts' "quiet 0s" is still unexplained (changelog
2026-11-22); Pro
conversions; Android 120 Hz and Bars & Sheets (build 2 had no dogfood
install, build 4 was tested by the user). Kick's web client prefers
Centrifugo - if Pusher stops being offered, that's the next transport
(`kick-chat-audit.md` § Native read).

**Open, remote access / backend:**
- **Rotate the RevenueCat v2 key** (pasted in chat 2026-11-07): new v2 key
  into `/etc/remote-relay.env` on the VPS + `systemctl restart
  remote-relay`, and `~/.config/obs-blade/revenuecat-v2.key` on the NAS;
  revoke the old one. Also check the RevenueCat dashboard has no ad /
  attribution integrations.
- **`/code-review high` not run yet** on the backend restart work
  (`336562a8..fa2ca8fe`), the relay link-end / pairing-expiry log
  (`dd18aa11`, relay 0.0.11), the bridge quick retries (obs-blade-remote
  `c9bdcec`, released as 0.4.1), the 30 s relay -> LAN retry
  (`54c885a2`, in 4.3.0), relay 0.0.13/0.0.14 + the Start OBS wait
  (`1bee9a99..`, 2026-11-22), and the bridge's OBS-answering check
  (obs-blade-remote `be0fb6c`, released as 0.4.2 without a device test).
- **Bridge state file, two processes:** plugin and standalone ship since
  OBS Blade Remote 0.4.0, and `Shared::update` (`core/src/shared.rs`)
  still saves its in-memory copy without reloading `bridge.json` first.
  With both running on one PC, one can write stale `app_keys` / key pair
  over the other's (phone then gets 4904 / 4911). Fix: reload inside
  `update`.
- Device checks of the restart work (relay restart on mobile data, PC
  offline after quitting the bridge, Kick sign-in, activity catch-up after
  a kick-events restart) once a master build is on the dogfood device.
- Backup restore (`tool/backup/README.md`) not drilled live.
- Optional: Hetzner Cloud server backups (~20 %); relay session resume
  for invisible restarts.

**Backend facts:** relay `https://relay.obs-blade.com` (VPS Quadlet
`remote-relay` 0.0.12 live, 0.0.14 published 2026-11-22 (diagnostic log lines; the fleet board's 04:00 patch run picks it up), `/etc/remote-relay.env`, RevenueCat project
`proja0a254d6`, `pro` = `entl2dd6e8fb75`); kick-auth 1.0.5 / kick-events
1.0.5 on the VPS since 2026-11-07; Quadlet health checks on all three;
backups every 6 h to `/volume1/docker/obs-blade-backups/` (NAS timer
`obs-blade-vps-backups`). Bridge = Kounex/obs-blade-remote
(`~/agent/obs-blade-remote`), 0.4.2 live (2026-11-22). No update hint
short of the relay's hard `min_version` (blocks older bridges), so users
only get it by downloading it again. Sessions end-to-end encrypted
(Noise IK) since relay 0.0.5. Spec:
`docs/superpowers/specs/2026-11-07-remote-relay-design.md`.

**F-Droid:** 4.2.0 live there (MR !53709 merged 2026-10-23). 4.3.0 goes
automatically: `UpdateCheckMode: Tags ^foss-` + `AutoUpdateMode: Version`,
the bot's next daily run (~06:00 UTC 2026-11-17) opens the MR, F-Droid
builds and must reproduce our APK. Checked 2026-11-16: signing cert =
`AllowedAPKSigningKeys`, a CI rebuild of `foss-4.3.0` is byte-identical
(SHA-256 `6207f9f1…`), same NDK / AGP / Flutter submodule as 4.2.0. NAS
timers `fdroid-check-4-3-0-*` (2026-11-17 / 19 / 21, 13:00) push
`tool/foss/fdroid-status.sh` results; exit 2 = stuck. Old 3.2.0 users must
uninstall first (key lost).

**Other follow-ups:**
1. **Creative assets**: v2 header + v3 search images and the 15 s "live
   image" videos (submissions `1ec1788c-…`, `58711c06-…`) - when approved:
   `release attach ios` (dry run, then --yes).
2. Upload key A6:24:44 "in review" -> after it resolves, delete
   `android/app/src/main/assets/adi-registration.properties` and discard
   Play internal-track draft `3.3.0 (2026090701)`.
3. GitHub #95: close only if the reporter confirms or doesn't answer.

**Store/Pro state:** products approved on both stores ($4.99/mo,
$49.99/yr, $99.99 lifetime); RevenueCat live (`pro`). Open: Apple Small
Business Program enrollment.

**Backlog threads (pick up as agreed):** Chatterino "medium" items
(`chatterino-comparison.md`); activity feed: StreamElements / Streamlabs
once API access is approved; Kick Centrifugo transport; intro v2
tablet/landscape check; media hub VLC mapping unprobed; Astra follow-ups.

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
| Branch | **`master`** (everything lands here; `feature/preview-transitions` merged 2026-10-07) |
| Users | 500k+ live — persistence + release paths are sensitive |
| Form factors | First-party **phone and tablet** — see `AGENTS.md` + `redesign/design-system.md` § Responsive layouts |
| Live version | **4.3.0** (build 2026111304, tag `4.3.0`) on both stores since 2026-11-16 |

### Machines

The maintainer works from a two-clone setup (headless analyze/test clone +
workstation simulator/device clone). Topology, paths, SDK locations, and
the dogfood handoff rule are maintainer-only and live in
`docs/private/maintainer-workflow.md` (gitignored). Contributors: ignore —
build and test from your own checkout per `AGENTS.md`.

Commit per verified unit proactively (small, logically-scoped commits).
Push when the user asks, and always at wrap-up/handoff — the remote is the
source of truth; never leave work local-only when handing over.

## Process notes (keep them)

- Default process: in-session, no plan doc; feature work (OBS, chat,
  sign-ins, UI in dashboard/chat) goes through the `feature-work` skill,
  including its end review (see `AGENTS.md` § Definition of done).
- Test gates on the NAS through **`dart tool/test_gate.dart`**
  (`--runs=N` for consecutive-clean proofs) - auto-retries the
  flutter_tester load flake. Full serial chat + persistence gate ≈ 5 min
  (~1150 tests). Don't run `flutter test` concurrently with analyze.
- Gotchas: a Hive `put` inside a `testWidgets` body hangs the file at
  teardown - wrap in `tester.runAsync` + `flush()`, or use a plain `test`.
  `test/flutter_test_config.dart` holds suite-wide network mocks.
  `/tmp` on the NAS is a 3.8G tmpfs - `flutter_tools.*` dirs filling it
  hang `flutter test` silently (`rm -rf /tmp/flutter_tools.*`). Always
  `flutter test -j 1` here; `build_runner` here re-resolves `pubspec.lock`
  to the older local SDK - `git checkout pubspec.lock` before committing.
  `pkill -f <pattern>` matching your own command kills your shell - kill
  by pid. Never answer an interactive `rm -i`/`cp -i` - use `-f`.
- Chat conventions: sheets on `BaseSheetScaffold` (every sheet in the app); mod rows from
  `dialogs/channel_mod_chrome.dart`; history rows `isHistorical` +
  `kChatHistoryOpacity` + `ChatHistoryDivider`; "LIVE"/live green = on air
  only (connection problems use markers); Kick/YouTube mod actions: always
  offer, map 403 to `chatNotModeratorText`; network-facing helpers get a
  live smoke as a throwaway `flutter test` file; Kick's `kick.com/api/v2`
  needs a browser UA.

## Verify quickly

```bash
git checkout master && git pull               # all work lands here
flutter test -j 1                            # serial on this box
dart analyze                                 # expect baseline infos, 0 errors
```

Maintainer: machine-specific verify, simulator, and visual-QA commands are
in `docs/private/maintainer-workflow.md`.

## Doc map

| Doc | Topic |
|---|---|
| [`AGENTS.md`](../AGENTS.md) | Short project rules + index |
| [`changelog-agent.md`](changelog-agent.md) | History of agent changes |
| [`redesign/2026-iteration/state-and-plan.md`](redesign/2026-iteration/state-and-plan.md) | 4.0 shipped; the doc now holds the phase-4 backlog + open decisions |
| [`chatterino-comparison.md`](chatterino-comparison.md) | Chatterino feature verdicts + YouTube channel→live design |
| [`superpowers/specs/2026-09-24-combined-chat-design.md`](superpowers/specs/2026-09-24-combined-chat-design.md) | Combined chat design (waves 1–3 shipped; plans in `archive/plans/`) |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, Pro gate live |
| [`chat-engines.md`](chat-engines.md) | Native chat engines + shared mechanics (shipped state) |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict |
| [`release-playbook.md`](release-playbook.md) | Store releases; skills `release-beta` / `-promote` / `-direct` / `-publish` |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
