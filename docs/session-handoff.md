# Session handoff

**Reset this file at every handoff — see "Handoff hygiene" below before editing it.**

Read this first after `AGENTS.md`. Last reset: **2026-09-24** (end of
the Chatterino-wave session: research + YouTube channel-follow + six
Chatterino ports, then dogfood follow-ups — pinned sheet headers, "New
messages" divider, optional YouTube entry name. 12 commits, pushed,
deployed to Kounex iOS. Details: `changelog-agent.md` 2026-09-24 entries).

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
| Branch | **`master`** (4.0 UI rework merged 2026-09-22; `redesign` kept as history) |
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

**Just closed: the chat session** (NAS, tier S, `12fa6d86..7f61c351`, all
pushed; the workstation is on `7f61c351` and "Kounex iOS" runs that
release build with `PRO_RELEASE_TEST_UNLOCK` + the Kick OAuth defines —
recipe in `docs/private/maintainer-workflow.md` § Dogfood release).
Research + verdict table: [`chatterino-comparison.md`](chatterino-comparison.md).

**On the device, user-approved so far:** the wave overall ("very good"),
pinned sheet headers + "New messages" divider (requested and shipped),
optional YouTube name (shipped after a correction: auto-names never carry
an `@`). **Not explicitly confirmed yet:** YouTube channel auto-rollover
across a real stream end, Twitch history backfill, autocomplete strip,
readability toggles, FFZ / zero-width emotes, highlighted/ignored users +
censor mode. Ask for feedback on these first.

**Chat conventions established this session (keep them):**
- Sheets: handle + title + back chevron pinned, only the body scrolls —
  build new sheets on `NativeChatSheetScaffold`.
- History rows: `isHistorical` on every engine's message model, dimmed
  via `kChatHistoryOpacity`, `ChatHistoryDivider` in the platform color.
- Shared filter reads go through `ChatFilterSettings`; appearance reads
  through `NativeChatAppearance`.
- Network-facing helpers get a live smoke as a throwaway `flutter test`
  file with an explicit `http.Client()` (plain `dart run` can't compile
  anything importing the freezed chat models) — the YouTube resolver's
  first two versions passed unit tests and failed live.

**Store/Pro state:** products exist on both stores with locked regionalized
pricing **$4.99/mo, $49.99/yr, $99.99 lifetime** (ASC 175/175 territories,
Play 173/173 regions). ASC products SUBMITTED for review 2026-09-08
(review screenshots uploaded) — watch for approval; Play products ACTIVE.
RevenueCat path is live (`pro` entitlement; keys pasted). Open: verify Play
RTDN test notification (Pub/Sub perms — service account admin again, retry);
sandbox dogfood per `revenuecat-setup.md` §5; enroll Apple Small Business
Program. Google developer verification DONE (`com.kounex.obsBlade`
Registered); upload key A6:24:44 still "in review" — after it resolves:
delete `android/app/src/main/assets/adi-registration.properties` and
discard Play internal-track draft `3.3.0 (2026090701)`.

**This session (2026-09-24 evening, NAS, tier S):** own "You" chat on
native Kick + YouTube (`dd4f4f1a`) and centered chat placeholders
(`ba5190e5`) — details in `changelog-agent.md`. **Not dogfooded yet**:
check on device that signing in to Kick / YouTube adds the "You" entry
(Kick: a username with `_` should resolve its `-` slug) and that an older
session picks the entry up after a restart (backfill).

**Open bug — Twitch native chat stalls after an announcement row** (from
dogfood): ~100 px blank under the announcement, 2 more messages, then
nothing. **Widget-level repro failed** (500-row buffer, announcement with
twin chat.message/link/emote/badge, zebra + timestamps on/off → every
row renders, stays pinned, no layout exceptions). Next: reproduce on
device with logs (Options → Debug samples, or a real `/announce`) and
check whether rows still reach the store (`TwitchChatStore.messages`
growing?) vs. a render/scroll problem; the EventSub notification path
logs every announcement's raw color (`Twitch announcement color=`).

**Immediate next threads:**

1. **The announcement stall above**, dogfood the new "You" entries, then
   feedback on the not-yet-confirmed chat items. The own-channel contract
   (`isViewingOwnChannel` on all three stores) is the base for the
   merged timeline in thread 2.
2. **Chat: Chatterino "medium" items** (`chatterino-comparison.md`
   verdict table): configurable mod buttons / timeout lengths, custom
   commands with OBS variables (scene, stream time), search operators
   (`from:`, `has:link`, `is:first-msg`), OBS-driven streamer mode, live
   dots in the channel dropdowns (Helix `streams` batch / Kick
   `livestream`). Then strategic: merged Twitch+YouTube+Kick timeline,
   7TV cosmetics (paints, personal emotes via EventAPI), live emote-set
   updates. YouTube follow-ups: OAuth own-channel path
   (`liveBroadcasts.list`), OBS `StreamStateChanged` → immediate
   re-resolve; watch Kick's Pusher → Centrifugo migration risk.
3. **Finish RevenueCat** (RTDN retry, sandbox dogfood §5, SBP enroll).
4. **Android runtime smoke** + release mechanics (version/changelog,
   `fastlane/metadata`, visual-QA pass).
5. YouTube quota spike (`tool/youtube_spike/`) — still pending.
6. Astra follow-ups (post-4.0 ok): conversation-owned drafts wave;
   optional live-session strip; syncOffset gating.

Process notes: `AGENTS.md` session-start checklist is resume-proof (run it
anyway). Default process tier **S**. Known flakes (don't chase): 4
`mod_action_sheet_test.dart` hit-test-offset failures (reproduce on the
pre-change tree too), `test/websocket/state_ordering_test.dart`
(intermittent), and random single-file "loading" `WebSocketException`s on
long multi-directory runs (rerun the file). **New gotchas this session:**
plain `dart run` can't compile anything importing the freezed chat models
(pulls in Flutter) — do live network smokes as a throwaway
`flutter test` file with an explicit `http.Client()`;
`test/flutter_test_config.dart` now exists (suite-wide network mocks —
extend it rather than adding per-file hacks). `pkill -f` patterns matching
`flutter` can kill your own shell — kill by pid.
Machine note (this box): **`/tmp` is a 3.8G tmpfs** — if it fills with
`flutter_tools.*` dirs, `flutter test` hangs silently in the kernel
compiler ("Free up space"); `rm -rf /tmp/flutter_tools.*` and re-run.
Also watch for **stale `flutter_tester` processes** lingering across
separate `flutter test` invocations in the same session (kill by pid,
`ps aux | grep flutter_tester`). Always `flutter test -j 1` here; running
`build_runner` here re-resolves `pubspec.lock` down to the older local SDK
and regenerates unrelated `.g.dart` files — `git checkout` those before
committing.

## Verify quickly

```bash
git checkout master && git pull               # all work lands here now
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
| [`redesign/2026-iteration/state-and-plan.md`](redesign/2026-iteration/state-and-plan.md) | 4.0 cold-start briefing (read first) |
| [`redesign/2026-iteration/ui-polish-audit-2026-09-21.md`](redesign/2026-iteration/ui-polish-audit-2026-09-21.md) | 4.0 polish wave: findings→fixes map, calibrations, leftovers |
| [`chatterino-comparison.md`](chatterino-comparison.md) | Chatterino feature verdicts + YouTube channel→live design (2026-09-24 wave) |
| [`chat-native-roadmap.md`](chat-native-roadmap.md) | Native chat API roadmap — waves 1–3 shipped, gate decision + wave 4 next |
| [`redesign-astra-audit.md`](redesign-astra-audit.md) | Astra redesign audit + ratified progressive-adoption verdict, verified master defects, harvest list |
| [`superpowers/specs/2026-09-14-command-ack-layer-design.md`](superpowers/specs/2026-09-14-command-ack-layer-design.md) | Command-ack layer (astra phase 2) — ratified design, merged 2026-09-18 |
| [`superpowers/specs/2026-08-09-mod-overflow-options-design.md`](superpowers/specs/2026-08-09-mod-overflow-options-design.md) | Mod overflow into Options |
| [`superpowers/specs/2026-08-09-chat-notice-meta-design.md`](superpowers/specs/2026-08-09-chat-notice-meta-design.md) | Notice meta + announce chrome |
| [`superpowers/specs/2026-08-09-chat-user-card-design.md`](superpowers/specs/2026-08-09-chat-user-card-design.md) | User card |
| [`chat-webview-audit.md`](chat-webview-audit.md) | Chat strategy |
| [`revenuecat-setup.md`](revenuecat-setup.md) | Pro subscription wiring + sandbox dogfood |
| [`private/`](private/) | Gitignored — monetization / backend / maintainer workflow |
