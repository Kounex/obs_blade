# Agent changelog

Running log of upgrade/migration work. Not store release notes.

## 2026-08-07 — Native chat: deleted content + actor reveal (mod view)

- Deleted messages now match twitch.tv's moderator view: the original
  content stays (text at half the marker's opacity, emotes at matching
  opacity) with an italic ` —Deleted` marker — replacing Wave B's
  `<message deleted>` tombstone. Uniform across single deletes, timeout/ban
  purges, and `/clear` purges; username + badges untouched.
- Tapping a message deleted via `channel.chat.message_delete` expands an
  inline reveal `<actor> deleted <chatter>'s message`. The DTO gains
  `userName` (the deleting moderator; `targetUserName` deliberately
  unmodeled — the chatter's name comes from the message itself), the store
  keeps a `_deletedMessageActors` map (pruned at the 500-cap, wiped with
  lifecycle), and the window owns a session-bounded expansion set.
  Purge/`/clear` payloads carry no actor — those rows are not tappable.
- Tests: DTO 1 updated, store 1 new + 5 updated, row 1 rewritten + 3 new,
  window 2 new + 1 updated (test counts: chat suites all green; analyze 0
  errors + 6 pre-existing warnings). No scopes, no persistence.

## 2026-08-06 — Native chat: message lifecycle (deletions + pause)

- `TwitchEventSubService` subscribes to four types now — `channel.chat.message`
  (mandatory, unchanged semantics) plus `message_delete`,
  `clear_user_messages`, `clear` (best-effort: POST failures/revocations
  degrade tombstones, never chat; same `user:read:chat` scope, no auth
  change).
- `TwitchChatStore` lifecycle state: plain tombstone id-set + system
  notices merged by arrival sequence (`lifecycleVersion` rebuild counter,
  `catalogVersion` pattern); pruned with the 500-cap; wiped on logout.
- Deleted messages tombstone in place (`<message deleted>`, username +
  badges kept) — single delete, timeout/ban purge, and `/clear` (which also
  inserts a "Chat was cleared by a moderator" banner). `/clear` on an empty
  chat is a no-op.
- Pause chip: scrolled-up chat now shows an explicit "Paused ↓" chip; new
  messages flip it to the existing "New messages ↓" pill; tap resumes.
- Tests: DTO (6), store lifecycle (8), service (3 new + 3 updated), wiring
  (1), row (1), window (3). Gates: chat + websocket + persistence suites
  green, analyze 0 errors (6 pre-existing warnings, none new).

## 2026-08-06 — Native chat: emote picker (first-party + 7TV/BTTV)

- `TwitchEmoteService`: Helix Get User Emotes (first paginated endpoint in
  the app — `after`-cursor loop, hard cap 50 pages); freezed
  `TwitchUserEmote` keeps `emoteType`/`emoteSetId` raw.
- `TwitchEmoteStore` (GetIt, session-scoped, MobX): channel/global split
  by owner, alpha-sorted, generation guard, `catalogVersion` pop-in +
  `isLoading` spinner signal; cleared on logout.
- New `user:read:emotes` scope (silent upgrade — pre-upgrade tokens skip
  the fetch and see a re-login CTA in the sheet, same philosophy as the
  write-scope lock strip). `canReadEmotes` mirrors `canWriteChat`.
- Dock seams: `NativeChatInput` takes an optional external
  controller/focusNode (never disposed by the dock) + a `leading` slot —
  still Twitch-free.
- Picker sheet: search + Channel/Global/Third-party sections (56pt cells,
  2x images, errorBuilder → code text), tap inserts `code + space` at the
  cursor and refocuses the dock; third-party section follows the existing
  7TV/BTTV toggle.
- Tests: service (4), store (5), wiring (3), dock (4 new), picker sheet +
  button (9). Gates: chat + websocket + persistence suites green, analyze
  0 errors (6 pre-existing warnings, none new).

## 2026-08-06 — Native chat: third-party emotes (7TV/BTTV)

- `ThirdPartyEmoteService` (7TV v3 + BTTV v3 — public, no auth): global +
  channel catalogs; 404 → empty map (no provider presence), other
  non-200 → `ThirdPartyEmoteException`; malformed entries skipped.
- `ThirdPartyEmoteStore` (GetIt, session-scoped, MobX): one merged
  catalog, precedence channel > global / 7TV > BTTV on ties, generation
  guard against superseded fetches, `catalogVersion` as the pop-in
  rebuild signal; cleared on logout.
- `TwitchChatStore`: fire-and-forget fetch on connect, gated by the new
  default-on `twitch-chat-third-party-emotes` Settings key (off → no
  third-party contact at all); clear on logout.
- Rows tokenize text fragments (exact, case-sensitive, space-split) and
  swap known tokens for 20px inline images (`Image.network`, animated
  WebP/GIF; errorBuilder → text). Toggle in the native chat options
  sheet ("Twitch — emotes" section).
- Tests: service parsing (9), store (7), wiring (3), row (7), view
  pop-in/toggle (2), sheet (1 new + 1 updated). Gates: chat + websocket +
  persistence suites green, analyze 0 errors (6 pre-existing warnings,
  none new).

## 2026-08-05 — Native chat send input (dock, write scope, Helix send)

- Native chat now **writes**: a send dock sits at the bottom of
  `NativeChatWindow` through its new optional `input` slot (rendered below
  the content with a `BaseDivider` hairline); wired in `stream_chat.dart`'s
  native branch inside the Observer (`onSend: twitchStore.sendChatMessage`,
  `onRelogin: startTwitchLogin`).
- New generic `NativeChatInput` (`stream_chat/native_chat_input.dart`):
  pill `TextField` + circular send button, hard 500 `maxLength` with no
  counter chrome, spinner while in flight, field clears on success, failed
  sends keep the text. Deliberately Twitch-free (plain params — the same
  reuse seam as the window for a future native engine). `canSend == false`
  swaps the field for a read-only lock strip ("Logged in read-only" /
  "Re-login to chat"); send failures surface as a transient inline error
  line above the dock.
- **Silent scope upgrade:** `kTwitchChatScopes` is now
  `['user:read:chat', 'user:write:chat']`. Nobody is logged out — stored
  sessions keep working read-only; `TwitchChatStore.canWriteChat` (plain
  non-reactive getter over the persisted `TwitchAuth.scopes`) gates the
  dock, and pre-upgrade logins get the lock strip with the re-login path.
- New `TwitchMessageService` (injectable `http.Client`, POST
  `$kTwitchHelixBase/chat/messages`, adds its own `Content-Type:
  application/json`) returning freezed `TwitchSendResult {messageId,
  isSent, dropReason}`; the guarded `TwitchChatStore.sendChatMessage`
  action (`@observable sendingChat` / `sendChatError`, `messageService`
  constructor seam) never throws — guards: not logged in / no write scope
  / empty message / already in flight.
- **Post-review fixes** (final whole-branch review caught what the suite
  couldn't): `drop_reason` is a Twitch **object** `{code, message}`, not
  the string the spec's "verified facts" claimed (spec corrected) — new
  `TwitchDropReason` DTO; `_dropReasonText` maps on `code` (AutoMod
  blocked/held, duplicate, rate-limited; unknown codes surface Twitch's
  own `message`, else "Message not delivered ($code)"). And cancelling the
  re-login dialog **mid-upgrade** now restores `loggedIn` when the stored
  session + user are intact — previously the UI claimed logged-out while
  the EventSub session kept streaming invisibly.
- **No optimistic insert by design** — the sent message renders via the
  existing EventSub echo; 200-but-dropped sends surface as the inline dock
  error, never a silent no-op.
- Spec/plan under `docs/superpowers/` (`2026-08-05-chat-send-input*`),
  commits `fdd539c..3f0cc56` (incl. docs + post-review fixes). Gates:
  **168/168** tests (+3 service, +7 store, +8 dock, +1 window slot, +4
  fix-wave), analyze 0 errors + the 6 pre-existing warnings. **Maintainer
  dogfood deferred** (test later) — checklist kept in
  `session-handoff.md`.

## 2026-08-05 — Native chat window (pane, status row, connection sheet)

- New `NativeChatWindow` (`stream_chat/native_chat_window.dart`) wraps the
  native engine everywhere it renders (mobile tab slot, standalone card,
  tablet card, streaming mode): inset pane (plain `cardColor` + hairline —
  the `BaseCard` surface; dogfood found the lightened control idiom read
  brighter than normal cards on a large pane), slim status row ("Stream
  Chat" label + state: connected / connecting… / reconnecting… / failed /
  offline), always tappable.
- Tapping the row opens a connection sheet: healthy → account + live-
  ticking uptime (`_UptimeLine`, 1s `Timer.periodic` accumulating from a
  captured base — `DateTime.now()` recompute is untestable under
  flutter_test fake-async); degraded → last error + Retry + Log out (same
  `ConfirmationDialog` as the account chip); offline → Connect.
- Reusable by construction: the window takes plain params (`ChatType`
  branding, generic `NativeChatConnectionStatus`, strings, callbacks) — no
  Twitch store types. Twitch mapping (`twitchChatWindowStatus`) lives at
  the `stream_chat.dart` call site; logged out always maps to `offline`.
- `TwitchChatStore` gains `@observable DateTime? chatConnectedAt`
  (in-memory; stamped on transition into `live`, kept during
  `reconnecting`, cleared on disconnect/failed) feeding the uptime line.
- Spec/plan under `docs/superpowers/` (`2026-08-05-chat-container-ui*`).
  Dogfood passed 2026-08-05 after one fix round (pane color, "Stream Chat"
  label, ticking uptime). Gates: 145/145 tests, analyze 0 errors + 6
  pre-existing warnings.

## 2026-08-05 — Native Twitch chat: role badges + visibility toggles

- `ChatMessageEvent` now models the payload's `badges` array
  (`ChatMessageBadge`: setId/id/info).
- New `TwitchBadgeStore` (GetIt, session-scoped, in-memory) caches the Helix
  global + per-channel badge catalogs, fetched by the new
  `TwitchBadgeService` with the existing user token (no new scope);
  `TwitchChatStore.connectChat()` kicks the fetch off fire-and-forget,
  `logout()` clears it.
- `TwitchChatMessageRow` renders badge images before the username
  (render-time lookup, channel catalog > global), skipped silently when
  unknown.
- New "Native chat options" sheet (44pt button in the native bar) with
  per-platform sections — Twitch today: 7 badge visibility toggles
  (broadcaster, moderator, VIP, subscriber, founder, bits, other),
  default-on, persisted as plain Settings-box bool keys
  (`twitch-chat-badge-*`), live re-filtering.

## 2026-08-04 (chat engine switch)

- **Chat engine switch (control-section redesign)** — spec
  `docs/superpowers/specs/2026-08-04-chat-engine-switch-design.md`, plan
  `docs/superpowers/plans/2026-08-04-chat-engine-switch.md`.
  - Persisted `ChatEngine` enum (`webView`/`native`, Hive typeId 14) +
    `SettingsKeys.SelectedChatEngine`; default WebView, so existing installs
    are unchanged.
  - `nativeChatAvailableFor(ChatType)` seam in
    `lib/models/enums/chat_engine.dart` — the future
    availability/entitlement gate for native chat plugs in there.
  - Username bar restructured: platform dropdown owns the left column
    (username dropdown only in WebView mode); right column =
    `ChatEngineSwitch` (Twitch only) + mode actions (`UsernameActionRow` for
    WebView — account chip removed; `TwitchAccountControl` for native — chip
    + disconnect dialog when logged in, "Connect Twitch" pill when logged
    out).
  - Slot: native view iff Twitch + native engine + logged in; native +
    logged out → connect empty state (pill relocated there); WebView engine
    → legacy stack regardless of login, empty state back to the username
    prompt only.
  - Disconnect dialog copy no longer claims the WebView takes over after
    logout.

## 2026-08-04 (native Twitch chat Phase 1)

- **Native read-only Twitch chat in the existing dashboard chat slot** —
  full Phase 1 landed on `master` (spec/plan under `docs/superpowers/`).
  Log in via OAuth **device-code grant** (DCF) — chosen over implicit/PKCE
  redirect flows so no localhost callback server or custom URL scheme is
  needed on mobile; dialog shows the code, user authorizes on
  twitch.tv/activate, polling completes login. Chat arrives over **EventSub
  WebSocket** (`channel.chat.message`), rendered natively with inline emotes
  + cheermotes and author colors. Read-only by design: no chat scope
  requested, no Helix send. **WebView fallback retained** for the logged-out
  state, YouTube, and Owncast — the chat slot swaps native ↔ WebView based
  on login state.
- **Files:** `lib/models/twitch_auth.dart` (Hive, typeId 13);
  `lib/utils/twitch/twitch_auth_service.dart` (device-code request, token
  polling/refresh/validate/revoke, own-user fetch) +
  `twitch_eventsub_service.dart` (EventSub WS: reconnect, watchdog,
  keepalive); `lib/stores/views/twitch_chat.dart` (GetIt `TwitchChatStore`:
  login state, token lifecycle, bounded message buffer); DTOs under
  `lib/types/classes/twitch/` (device code, token, user, EventSub envelope,
  `channel_chat_message` — freezed); UI
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/` (`stream_chat.dart`
  slot switch, `native_twitch_chat_view.dart`, `twitch_chat_message_row.dart`,
  `twitch_device_code_dialog.dart`) + `username_action_row.dart`
  connect/logout actions; `http` added as the single new dependency; tests
  under `test/chat/` + `test/persistence/twitch_auth_persistence_test.dart`
  with `test/chat/fixtures/twitch/` message fixtures.
- **Client ID:** `t3muhu36do5wemeeilzl57v48gwcmh` (public — no secret in
  DCF), hardcoded once in `lib/utils/twitch/twitch_auth_service.dart`.
- **Robustness fixes during execution:** EventSub subscription POST failures
  are routed to `onRevoked` (token treated as dead → clean logout state
  instead of a stuck "connecting" WS); cold-start token validation is
  offline-safe (network errors keep the stored session, only a definitive
  401 logs the user out).
- **Verify:** `flutter test test/chat/ test/websocket/ test/persistence/`
  87/87; `flutter analyze` 0 errors (only the 6 pre-existing warnings:
  `input.dart` ×2, `translucent_sliver_app_bar.dart` ×2, `statistics.dart`
  ×2); build_runner clean (no drift). Manual dogfood on a real Twitch
  account pending (maintainer) — incl. the open point whether the WebView
  fallback re-renders after logout given `_syncWebController`'s
  unchanged-URL early-return (`stream_chat.dart`).

## 2026-08-03 (redesign finish batch)

- Stats entry→detail **Hero removed** (plain push); `HeroMode` workaround in
  paginated list gone with it.
- **Unified onboarding:** GettingStarted → WS setup + light app-tour slides;
  deleted OBS version fork (`version_selection`, `twenty_eight_party`,
  `back_so_selection_wrapper`). Screenshot walk updated.
- **Reorder previews** tightened to reuse real leaf widgets (`BaseCheckbox`,
  `BaseDropdown`, `BaseButton`, `StatTile`, scene-item/audio chrome).
- **`DashboardElementsOrder` wired** into live `DashboardContent` via
  `dashboard_element_layout.dart` — compose-when-adjacent (mobile tabs /
  tablet side-by-side for Scene Items↔Audio and Chat↔Stats).
- **Phone + tablet product rule** documented in `AGENTS.md` + design-system
  § Responsive layouts; order screen hint; Force Tablet Mode noted for QA.
- Verify: persistence/chat/websocket tests **38/38**; analyze 0 errors on
  touched paths. Landed as `23248b7` on `origin/redesign`.
- **2026-08-03 MacBook close-out:** maintainer accepted the finish batch
  visually; `redesign` merged into `master`. Soft leftovers: connect-overlay
  motion pass; Twitch console registrations (deferred).

## 2026-07-27 (redesign branch)

- **"On Air" visual overhaul on branch `redesign`** (later pushed; tip through
  finish batch is `23248b7`). Full audit (15-agent swarm →
  `docs/redesign/audit-digest.md`), design spec (`docs/redesign/design-system.md`),
  session notes (`docs/redesign/session-notes.md`).
- New design module `lib/shared/design/`: motion/spacing/radius tokens,
  `AppStatusColors` ThemeExtension, app text theme, `Pressable`,
  `StaggeredEntrance`, `AnimatedResultIcon`, `CountUpText`.
- `lib/app.dart` theme factory modernized (real textTheme, pageTransitionsTheme,
  dialog/snackBar/chip sub-themes, status extension) — custom-theme hex→slot
  semantics and all persistence contracts unchanged; zero functional change rule.
- 11-agent restyle: shared UI kit, tab transition, intro cinematic, home,
  dashboard (on-air status cluster replaces `stream_rec_timers.dart`, audio
  mixer gradient meters, chat chrome), statistics (chart draw-in + gradients,
  staggered lists, hero entry→detail), settings (support dialog skeleton +
  icon tiles), custom theme editor (preview cards + 8th appBar bubble), data
  mgmt/logs/customisation (mock previews replace PLACEHOLDERs).
- Verify: `flutter analyze` 143 issues / **0 errors** (master baseline 269);
  `flutter test test/chat test/websocket test/persistence` 38/38; debug build on
  iPhone simulator (release/profile unsupported on this sim image).
- **Visual-QA round:** screenshot harness (`integration_test/screenshot_walk_test.dart`
  + `tool/visual_qa/capture_screenshots.sh`, `--no-uninstall` permanently after a
  sim-data wipe incident — see `docs/redesign/session-notes.md`); 37-shot walk
  incl. live dashboard via local OBS; 6-agent visual inspection (~90 polish
  findings); 8-agent fix swarm (overflow root causes, surface derivation, tab-bar
  unification, copy pass, subpage headers, intro slide frames, Connect button
  wrap, …). Post-fix: analyze 138 / 0 errors, tests 38/38, re-shoot for
  spot-check.

## 2026-07-27

- **Public-repo docs pass:** repo is public — scrubbed tracked files of the
  local OBS dev password, simulator UDID, username-absolute paths, and
  machine nicknames; generalized E2E/tooling docs so any contributor's agent
  can follow them; maintainer-specific machine notes marked as such. Rule
  recorded in `AGENTS.md` (docs hygiene).
- **Merged the upgrade batch to `master`** (fast-forward), deleted
  `chore/flutter-deps-upgrade` (local + origin). Docs now describe a
  master-based flow; open before store release: Android build/test,
  version/build-number bump.
- **Persistence device proof DONE** (release gate closed): master-era dev
  build over the App Store app on a real ~2.5y-old iPhone install (worktree
  `obs_blade_master_check` + 5 throwaway compile shims — master itself
  untouched), real boxes pulled via `devicectl` (`build/phone_backup/`),
  simulator rehearsal passed, CE profile build installed, user verified all
  data, CE write to `app-log.hive` proven. Learnings: debug builds crash on
  cold home-screen launch (flutter#149214) → use profile/release on device;
  `devicectl ... process launch --console` broken in this Xcode (error
  10002) → verify via process list + container pulls.
- Bumped `keyboard_actions` to `^4.2.1` — 4.2.0 breaks the iOS simulator
  build on Flutter 3.44 (`SemanticsConfiguration.isFocused` now `bool?`;
  fixed upstream in 4.2.1). First real device/sim build of the branch.
- Added local OBS ↔ simulator E2E loop on the MacBook
  (`docs/local-obs-e2e.md`): `tool/obs_local/obs_test_env.sh`
  (start/stop/status for the real OBS instance, reuses running OBS, minimizes
  window) + `tool/obs_local/ws_smoke.dart` (standalone Hello → Identify →
  Identified + GetVersion/GetSceneList/GetInputList probe mirroring
  `AuthenticationHelper` semantics; no new deps). Tests run against the
  existing `Untitled` profile/scene collection per user direction.
- Committed + pushed `chore/flutter-deps-upgrade` so MacBook
  (`~/development/flutter/obs_blade`) can mirror NAS for simulator testing.
- Folded MacBook-only order-list bottom padding (`kBottomNavigationBarHeight`)
  into the branch before push.
- Updated handoff/AGENTS for dual-machine roles (NAS = analyze/test; Mac = sim).

## 2026-07-25

- Cloned repo; lean `AGENTS.md` + `docs/`.
- Flutter **3.44.8** at `~/flutter`; branch `chore/flutter-deps-upgrade`.
- Migrated **Hive → Hive CE**; regenerated adapters; typeIds/fields verified.
- Built **foundation mock data** + committed `*.hive` boxes; open / cold-open /
  copy-reopen tests (`test/persistence/`).
- Classic **hive 2.2.3** writer (`tool/classic_hive_writer/`) → CE open proof
  (`classic_boxes/` + `hive_classic_to_ce_test.dart`); **17** persistence tests
  passing.
- Raised SDK to `^3.12.0`; bumped majors (get_it 9, fl_chart 1, slidable 4,
  plus packages, intl, …); replaced `qr_code_scanner` with `qr_code_scanner_plus`.
- `flutter analyze`: **0 errors**.
- Documented OBS WebSocket v5 architecture for agents
  (`docs/obs-websocket-architecture.md`): layers, handshake, request/event/batch
  patterns, inventories, DashboardStore role, legacy event-name pitfalls.
- **WebSocket connect harden:** conditional Identify auth, 10s staged handshake,
  `ConnectionAttemptResult` UX, `websocketUri` + domain default `ws://`, stream
  pump ownership, QR `obswss://`, FAQ + `docs/websocket-connect-audit.md`,
  `test/websocket/handshake_helpers_test.dart`.
- **DashboardStore WS audit** (`docs/dashboard-store-websocket-audit.md`): fixed
  `SceneListChanged` name, pause stats during collection change, lighter scene
  switch refresh, scoped scene-item enable updates, always track studio mode;
  requestStatus guards + safer UUID lookups on Get/batch handlers.
- **Chat WebView audit** (`docs/chat-webview-audit.md`): Twitch/YT/Owncast embed
  approach vs native EventSub/Helix / YouTube Live Chat APIs; recommended hybrid.
- **Chat Phase 0:** YouTube Live Chat API visibility check documented; fixed
  video-id parsing (`extractYouTubeVideoId`), WebView recreate-on-rebuild, dialog
  copy/validation; Owncast trailing-slash normalize. Tests in `test/chat/`.
- **Session close:** `docs/session-handoff.md` written for next agent; AGENTS.md
  points at it. Chat Phase 1 (native Twitch) parked pending Dev Console creds.
