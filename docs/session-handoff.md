# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-10-21** (4.2.0
released).

**Live:** 4.2.0 (build 2026102003, tag `4.2.0`) on both stores since
2026-10-21 (App Store `READY_FOR_SALE`, Play production 100 %). Branch `master`. Releases run through
**store-release** (`release.yaml`).

App Store versions: `release metadata ios` does **not** create a
version (the tool says "create version x in App Store Connect first").
4.2.0 was created with one `POST v1/appStoreVersions` through the tool's
`HttpApiClient` (one-off script, removed); the iPhone App Preview was
copied over by App Store Connect.

Release env on the MacBook: `release-env.sh` puts mise's Ruby 3.4.2
first (fastlane lives there; Homebrew Ruby is 4.0 without it; was rbenv
until 2026-10-27) and
`release()` is store-release - runbook updated.

Dogfood (Kounex iOS, `31139f46`): YouTube streaming confirmed in the log
("reads over the stream"), Kick connects again. Still to see on the
device: the hourly "YouTube API: ≈… units" line (~1,700 per chat-hour).
Not verified: whether streamed answers repeat `activePollItem` (needs a
chat with a running poll).

**GitHub (2026-10-21, in the user's voice):** #100, #96, #93 answered +
closed. #95 answered (iOS fix in 4.2, asked which platform + to retest) -
close only if they confirm or don't answer. Email from an Android volleyball streamer (instant-replay.lua
hotkey): answer drafted in the 2026-10-17 session; the user sends it.
The Pro customer who ran out of YouTube quota: no mail from us (user's
call); 4.2 cuts their chat to ~1,700 units/h.

**FOSS build (2026-10-22, `docs/foss-build.md`):** master builds the
GitHub APK + F-Droid (`kFoss`, `tool/foss/prepare.sh`, Pro left out).
**`foss-4.2.0` is live on GitHub Releases** (Latest; tag on `e0edf45c`
- moved once before anything was published: the first tag build ran out
of Gradle heap, fixed by 4G). F-Droid: **fdroiddata MR !53709**
(branch `obs-blade-4.2.0` on the user's fork, made via the Commits API
with `start_project` - the fork's master is from 2023 and GitLab's
sync-fork doesn't apply a 54k-commit gap). MR pipeline **green**:
F-Droid's build reproduced our GitHub APK byte for byte ("compared built
binary to supplied reference binary successfully"). Review round 1
(licaon-kter) done: `--enforce-lockfile` -> committed `pubspec-foss.lock`
(`prepare.sh lock`, CI `lock --check`), `commit:` is now the hash
`9722799a` (one commit after the tag, APK byte-identical `13ee8eb4`, tag
NOT moved), 3.2.0 `disable`d, old key dropped. Next: further review
replies in the user's voice; after merge + publish, check the F-Droid
page. Old 3.2.0 users must uninstall first (key lost) - the F-Droid
client won't offer the update across signers, so the note is in the
listing description, not only the changelog. Not done: on-device
check on a real Android phone (emulator only).

**Kick services run on the Hetzner VPS since 2026-11-07** (moved
unattended 07:00-07:16 UTC, no rollback; Hetzner leftovers removed by
`kick-hetzner-cleanup.timer` on the NAS on 2026-11-14 once a real Kick
event reached the VPS relay).

**In progress: Remote relay (Pro, reach OBS from anywhere)** - spec
`docs/superpowers/specs/2026-11-07-remote-relay-design.md`, map
the README of Kounex/obs-blade-remote (`~/agent/obs-blade-remote`, the desktop side since 2026-11-09).
- **4.3.0 = the remote access release, prepared 2026-11-13** (version
  `4.3.0+2026111301`, store notes + TestFlight checklist, listings,
  paywall card "Control OBS From Anywhere" second, FAQ, store screenshots
  with the remote slide 5 of 8 - real relay captures, see
  `tool/store_screenshots/README.md` "Remote access (Pro) shots").
  Order (user decision 2026-11-13: public downloads + site with the app):
  1. **Done 2026-11-13:** dogfood OK (user), `release-beta` uploaded
     4.3.0 (2026111301): TestFlight internal (VALID) + Play internal.
     **Superseded by build 2 (2026111302, user 2026-11-13):** adds 120 Hz
     on Android (#106) + Settings -> Bars & Sheets (Glass / Clear / Solid)
     and fixes the double tab bar blur; notes / TestFlight checklist / F-Droid
     changelog `2026111302.txt` updated. Uploaded 2026-11-13 (user asked
     to skip the dogfood install): TestFlight internal (VALID) + Play
     internal. **Superseded by build 4 (2026111304, user 2026-11-13,
     no dogfood install):** build 3 = `/code-review high` fixes over
     `4.2.0..HEAD` (relay keeps the saved password, Wi-Fi back never ends
     a working relay session, Turn Off confirms, deleting a paired
     connection removes it on the relay); build 4 = relay -> LAN check
     every 30 s on Wi-Fi (`_retryLan`). Both uploaded to TestFlight
     internal + Play internal. Next: user tests build 4 (TestFlight
     checklist), then `release-promote` it (after 3 + 4 below).
     Open device question: does iOS briefly report cellular-only while
     roaming between mesh APs (would hop a LAN session to the relay)?
  2. **Done 2026-11-13 (user: out now, so dogfood and App Review work):**
     `v0.4.0` tagged in Kounex/obs-blade-remote (release with the five
     downloads) and the site deployed: `/remote`, privacy policy
     `#remote`, remote guide, landing row + Pro section. **Left for
     publish day:** the What's new 4.3 tab - branch `whats-new-4-3` in
     `~/agent/obs-blade-site` has it (dated "November 2026"; merge,
     adjust the month if needed, `./deploy.sh`).
  3. App Store privacy labels + Play Data safety against the relay's data
     (policy `#remote`: device name, RevenueCat anonymous ID, OBS status;
     sessions end-to-end encrypted).
  **Done 2026-11-14 (prep for `release-promote`):** App Store version
  4.3.0 created via the API (`f68d4bd2-…`, releaseType MANUAL like
  4.2.0; contact copied by ASC), review notes = 4.2.0's + the remote
  access paragraph below, `release metadata ios --yes` (notes + 16
  screenshots), iPhone App Preview carried over (COMPLETE). Play listing
  changed since 4.2.0 -> `release metadata android` at promote time.
  Privacy forms (3.) are the user's (no API for Apple; Play's dataSafety
  API overwrites the whole form) - answers in the 2026-11-14 session.
  4. ~~App Review notes~~ (done, text as below), e.g.:
     "Remote access (Pro, new in 4.3) reaches OBS Studio on a computer
     through our relay when the phone isn't on the same network. It needs
     OBS Studio plus our free companion app OBS Blade Remote
     (obs-blade.kounex.com/remote) on that computer; setup runs once while
     the phone is connected to OBS on the local network (globe on the
     dashboard -> Set Up Remote Access). Sessions are end-to-end encrypted;
     the relay can't read them. Everything else works without the
     companion app." Attach a screen recording if review asks.
- **End-to-end encrypted since 2026-11-08** (relay 0.0.5, bridge
  0.3.1 - 0.0.5 adds the bridge keepalive pong: websocket pings don't
  cross the Cloudflare tunnel): the relay can't read sessions; keys are exchanged through OBS
  when pairing. Pairings from before have no keys and count as unpaired.
- **Relay live** at `https://relay.obs-blade.com` (VPS, Quadlet
  `remote-relay`, image 0.0.5, `/etc/remote-relay.env` with the RevenueCat
  v2 key - NAS copy `~/.config/obs-blade/revenuecat-v2.key`, project
  `proja0a254d6`, `pro` = `entl2dd6e8fb75`). Live checks through
  Cloudflare passed: non-Pro pairing 403, bad bridge token 401, close code
  4904 reaches the phone. **The key was pasted in chat once (2026-11-07):
  rotate it** (new v2 key, replace both copies, `systemctl restart
  remote-relay`, revoke the old one).
- **End to end through Cloudflare: green** (2026-11-08, relay 0.0.4,
  OBS 32.2.2 on the MacBook, `obb` 0.3.0 as bridge, `noiseprotocol` as
  the phone): key exchange via OBS, encrypted session, 640 px preview,
  195 KB message over 4 frames, meters, status snapshot, 1003 for
  plaintext, 4904 for an unknown key, 4901 after OBS quit. 0.0.3 fixed relay-ended sessions arriving as 1006 through
  cloudflared (close only from the socket's handler).
- **Bridge core** `core/` in Kounex/obs-blade-remote (Rust, 20 tests; e2e green against OBS
  32.2.2 on the MacBook with and without OBS auth, local relay).
- **App** (commits e33643b0..02260328): relay routing in `NetworkStore`
  (smart fallback), close codes 4900-4910 with copy, pairing store +
  dashboard sheet (globe in the dashboard bar), card line, Start OBS
  offer. Tests `test/remote/`, shots `tool/widget_shots/remote_access_shots_test.dart`.
- **Dogfood path before the plugin exists:** run `obb` (the core's CLI) on
  the MacBook next to OBS as the bridge (`~/agent-build/obb_dogfood.py`
  wraps it: OBS watcher + Start OBS, log `~/agent-build/obb-dogfood.log`); the dogfood device's RevenueCat
  app user id must have Pro (or sit in `RELAY_PRO_ALLOW`).
- **Before a second bridge process (plugin + standalone) ships:**
  `Shared::update` saves its in-memory copy without reloading
  `bridge.json` first (`set_enabled` / `set_preview` /
  `set_obs_override`) - one process could write back stale `app_keys` or
  key pair over the other's (phone then gets 4904 / 4911). Reload inside
  `update` (review 2026-11-08; not reachable while `obb` is the only one).
- Next: plugin shell (C++, vendor `obs-blade-bridge`/`Pair`), Qt panel +
  standalone tray/watcher, packaging (macOS notarized, Windows unsigned
  for now, Linux). MacBook has rustup + cmake (Homebrew); build scratch
  `~/agent-build/`.

**Watch:** crash reports + reviews for 4.2.0 (new: preview
transitions, combined chat Save / Delete - build 5 had no device check;
Kick chat complaints should stop). Kick's web client prefers Centrifugo now - if
Pusher stops being offered, that's the next transport (`kick-chat-audit.md`
§ Native read). Open follow-ups:

1. **Creative assets**: v1 header + search images are live (4.1.0 en-US).
   In review: **v2 header + v3 search images** (2026-10-11, submission
   `1ec1788c-…`) and the same compositions as **15 s "live image" videos**
   (assets `eec00005-…` header / `2cc00005-…` search, submission
   `58711c06-…`; store-shots cuts `appstore-header` / `appstore-search`,
   never committed). **When approved:** `release attach ios` (dry run,
   then --yes); then ask for phone screenshots / a recording of how iOS
   plays them.
2. Upload key A6:24:44 still "in review" → after it resolves, delete
   `android/app/src/main/assets/adi-registration.properties` and discard
   Play internal-track draft `3.3.0 (2026090701)`.

**Store/Pro state:** 4.2.0 live; products approved on both stores
($4.99/mo, $49.99/yr, $99.99 lifetime); RevenueCat live (`pro`); Play
RTDN test received. Open: Apple Small Business Program enrollment.

**Backlog threads (pick up as agreed):** Chatterino "medium" items
(`chatterino-comparison.md`); activity feed next: StreamElements /
Streamlabs once API access is approved; Kick Centrifugo transport (see
Watch); intro v2 tablet/landscape check; media hub VLC mapping unprobed;
Astra follow-ups.

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
| Live version | **4.2.0** (build 2026102003, tag `4.2.0`) on both stores since 2026-10-21 |

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
