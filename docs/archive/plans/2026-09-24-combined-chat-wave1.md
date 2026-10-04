# Combined chat — Wave 1 (read-only merge + "My chats") plan

> Spec: [`../specs/2026-09-24-combined-chat-design.md`](../specs/2026-09-24-combined-chat-design.md)
> (approved 2026-09-24 incl. the "shared" vs. "restore" resolution).
> **Tier L** (persistence + all three chat stores). Executed in-session by
> the controller with commit-per-task; one end reviewer subagent on the
> full wave diff before the dogfood handoff.

**Goal:** `ChatType.Combined` → a native, Pro-gated, read-only timeline
interleaving the signed-in account's own Twitch / YouTube / Kick chats
("My chats"), with per-source status dots, platform icons on rows and
stacked, individually tuckable pins. No builder, no writing, no focus
shortcut (waves 2–3).

## Global constraints

- `master`, commit per task, `git add` only the task's files.
- `dart analyze lib test`: 0 errors, no new warnings in touched files.
- Codegen (checklist §3): all MobX-annotated edits first, ONE
  `dart run build_runner build --delete-conflicting-outputs`, then
  `git checkout pubspec.lock` + any unrelated `.g.dart` churn.
- Hive writes never inside a `testWidgets` fake-async body — do them in
  `setUp` or `tester.runAsync`.
- Static members don't cross the MobX `Store = _Store with _$Store` alias
  (e.g. `TwitchChatStore.kMaxMessages` doesn't compile) — use literals.
- Tests run `-j 1`, never concurrent with analyze.

## Verified facts the plan relies on

- `ChatType` adapter (`chat_type.g.dart`) reads unknown bytes as
  `Twitch` → appending `@HiveField(4) Combined` is downgrade-safe.
- Exhaustive `switch (chatType)` sites needing a `Combined` arm:
  `chat_type.dart` (`text`, `icon` maps), `chat_type_brand.dart`,
  `username_dropdown.dart`, `username_action_row.dart` (×3),
  `dashboard_content_streaming.dart:389`, `stream_chat.dart`
  (`_ChatEmptyState._addUsername`). Non-exhaustive `==` chains
  (`delete_username_dialog`, `anyChatActive`, `_urlForChatType`) fall
  through safely.
- `nativeChatAvailableFor` (`chat_engine.dart:29`) gates the engine
  switch and the native slot; Combined is native-only → the slot must
  bypass the persisted `SelectedChatEngine` for Combined.
- Row timestamps: Twitch `ChatMessageEvent.receivedAt` (EventSub
  `message_timestamp`; history sets it from IRC `tmi-sent-ts`), YouTube
  `publishedAt` (always set), Kick `createdAt` (nullable).
- Twitch notices are positioned by `afterSeq` (no timestamp) and merged
  by `TwitchChatStore.messagesWithNotices()` → Twitch contributes that
  merged list as ONE ordered stream; notices inherit the sort key of the
  message before them.
- Pins: `TwitchChatStore.pinnedMessage` (`TwitchPinnedMessage`),
  `KickChatStore.pinnedMessage` (`KickChatMessage`), YouTube has none.
  `PinnedChatBanner` owns its tuck state and positions itself top-right
  over `child`.
- Stick-to-bottom keys on count + newest id since `c8c48713` — the merged
  view copies that pattern (newest = last merged item key).

## Tasks

### Task 1 — `ChatType.Combined` + settings keys

- `chat_type.dart`: `@HiveField(4) Combined` (append-only comment kept),
  `text: 'Combined'`, icon `CupertinoIcons.square_stack_3d_up`-style
  (use an existing `JamIcons`/`CupertinoIcons` glyph; no new asset).
  Regenerate `chat_type.g.dart`.
- `chat_type_brand.dart`: `Combined => null` (neutral, like Owncast).
- `nativeChatAvailableFor`: unchanged (Combined has no engine choice);
  new `bool isNativeOnly(ChatType)` → true for Combined.
- Every exhaustive switch listed above gets a `Combined` arm (no
  WebView URL, no username list, streaming overlay `chatActive` = true).
- `SettingsKeys.MyChatsDisabledPlatforms` (`List<String>` of
  `ChatType.name`) + its key string.
- Tests: `test/persistence/` adapter round-trip for `Combined` + an
  unknown-byte read (→ Twitch); chat-type dropdown lists Combined.

### Task 2 — `CombinedChatStore` (source resolution + activation)

New `lib/stores/views/combined_chat.dart` (MobX, GetIt singleton in
`main.dart` next to the other chat stores; injectable store resolvers +
`isProResolver` for tests).

- `CombinedSource { ChatType platform; String key; String label; }` —
  key = Twitch `null`-own (selectedChannelId null), YouTube
  `kYouTubeOwnChannelLabel`, Kick own slug.
- `@computed List<CombinedSource> mySources` — from each store's own
  entry (Twitch: `isLoggedIn` + `user`; YouTube: `ownChannel`; Kick:
  `ownChannelSlug`), minus `MyChatsDisabledPlatforms`.
- `activate()` / `deactivate()`: remember each involved store's current
  selection (`_restore`), select the source, `connectChat()`; on
  deactivate restore the remembered selection. Idempotent; re-run when
  `mySources` changes while active (a sign-in adds a source live).
- `@computed Map<ChatType, CombinedSourceStatus> sourceStatus` —
  `live / connecting / offline / needsSetup / error` from each store's
  connection state (+ Twitch `isLoggedIn`, YouTube `authState ==
  unconfigured` → needsSetup, `awaitingLiveStream` → offline).
- Activation trigger: a reaction in `StreamChat` (Task 4) calls
  `activate()` when `SelectedChatType` becomes Combined and
  `deactivate()` when it leaves — the store never reads the settings
  box's chat type itself (testable without widgets).
- Tests (`test/chat/combined_chat_store_test.dart`, fake stores via the
  existing fakes): my-sources derivation + disabled toggle; activate
  selects own entries and deactivate restores prior selections
  (positive-before / negative-after); status mapping per platform.

### Task 3 — merged timeline

In `CombinedChatStore`:

- `sealed class CombinedItem { ChatType platform; Object payload;
  DateTime? at; String key; }`.
- `@computed List<CombinedItem> timeline` — Twitch
  `messagesWithNotices()` (notices take the preceding message's time),
  YouTube `messages`, Kick `messages`; stable merge by `at` (null → the
  previous item's time within its own stream, so each platform's
  internal order never changes), capped to the newest 500.
- Reactivity: read `TwitchChatStore.lifecycleVersion` + the observable
  lists so tombstones/notices recompute.
- Tests: interleave by time; per-platform order preserved even when
  timestamps tie or are missing; cap keeps the newest; a Twitch notice
  stays right after its message.

### Task 4 — `NativeCombinedChatView` + slot wiring

- `stream_chat.dart`: `Combined` → native slot regardless of
  `SelectedChatEngine`, still behind the Pro `Observer` gate; a
  `reaction` on the chat type drives `activate/deactivate`.
- New `native_combined_chat_view.dart`: one `ListView.separated` over
  `timeline`, per item the platform's existing row
  (`TwitchChatMessageRow` / `TwitchChatNotificationRow` / system notice,
  `YouTubeChatMessageRow`, `KickChatMessageRow`) wrapped in a leading
  platform icon (brand-colored `chatType.icon`, 12 px, `Semantics` label
  "from Twitch"). Shared filters (`ChatFilterSettings`), zebra, history
  divider (neutral color), announce-twin hiding (reuse the Twitch view's
  rule), stick-to-bottom with count + newest key, scroll pill.
- Read-only: long-press = Copy only (`showMessageActionSheet`); author
  tap opens the platform's user card.
- `NativeChatWindow` for Combined: title "Stream Chat", `chatType:
  Combined`, status = best of the sources, `onStatusTapOverride` opens a
  small sources sheet (per-platform status + fix action: sign in / set
  up / retry). No input dock.
- Empty state (no sources): `_ChatEmptyState` copy "Sign in to Twitch,
  YouTube or Kick natively to combine your chats." with the connect
  buttons of the platforms not signed in.
- Tests (`test/chat/native_combined_chat_view_test.dart`): rows from all
  three stores render in time order with their icons; filters apply;
  full-buffer stick-to-bottom (mirror of the Twitch regression test);
  empty state without sources.

### Task 5 — status strip, stacked pins, chat bar

- Status strip under the window header: one dot + icon per source
  (`sourceStatus`), tap → that platform's fix action.
- Pins: `Column` of up to two `PinnedChatBanner`s (Twitch, Kick) each
  given a platform-icon `leading` slot (new optional param on the
  banner) — each keeps its own tuck state (already per-instance). Layout:
  banners stack top-down; tucked pins stack right-aligned under each
  other. Needs a `PinnedChatBanner.stackIndex` (vertical offset) since
  the banner positions itself.
- Chat bar: for Combined, the username slot shows a static "My chats"
  control (dropdown lands in wave 2) with per-platform toggles in the
  options sheet (`MyChatsDisabledPlatforms`); engine switch hidden.
- Options sheet: Combined root = Appearance + the per-platform notice
  pages of the platforms in the combo.
- Tests: strip renders one dot per source with the mapped status; two
  pins render, tucking one leaves the other open; chat bar hides the
  engine switch for Combined.

### Task 6 — docs + gate + review

- `AGENTS.md` chat section, `changelog-agent.md`, handoff.
- Full gate: `flutter test -j 1 test/chat/ test/websocket/
  test/persistence/` + analyze.
- One reviewer subagent over the wave diff with checklist §2 probes;
  fix loop; push; workstation pull; dogfood handoff note.

## Out of scope (waves 2–3)

Builder sheet, saved combos, other-streamer sources + suggestions,
focus shortcut / "↩ Combined", YouTube background pause, writing, mod
actions, emote picker/autocomplete in Combined.
