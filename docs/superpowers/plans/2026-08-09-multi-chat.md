# Multi-Chat Implementation Plan (Tier M — mini-plan)

> **For agentic workers:** execute task-by-task in order; each task ends with
> its own commit. Tier M: one implementer subagent for the whole wave, one
> end reviewer. TDD per task — write the failing test first, then implement.
> Spec: [`docs/superpowers/specs/2026-08-09-multi-chat-design.md`](../specs/2026-08-09-multi-chat-design.md)

**Goal:** Let native Twitch chat users add other streamers' chats (search /
moderated / followed discovery), switch between them via a chat-bar
dropdown, and run mod actions (delete / timeout / ban) where they moderate.

**Architecture:** Parameterize the `TwitchChatStore` singleton — an
effective broadcaster id (selected channel or own) is threaded through
EventSub subscription conditions, sends, and catalog fetches. Only the
visible channel holds live subscriptions; switching tears down and
re-creates subs on the same websocket session. Per-channel in-memory
message buffers restore history on switch-back. Catalog stores become
per-broadcaster keyed. WebView engine untouched.

**Tech Stack:** Flutter, MobX (+ build_runner codegen), GetIt, Hive CE
(settings box), `package:http` injectable clients, Twitch Helix + EventSub
websocket.

## Global Constraints

- New scopes ride `kTwitchChatScopes` in
  `lib/utils/twitch/twitch_auth_service.dart` — exact additions:
  `user:read:follows`, `user:read:moderated_channels`,
  `moderator:manage:chat_messages`, `moderator:manage:banned_users`.
- Own channel is derived from `TwitchAuth` (never stored in the channels
  list); `SelectedNativeChatChannelId == null` means own channel (default —
  zero behavior change for existing users).
- Chat content never touches Hive — per-channel buffers are in-memory only.
- `channel.moderate` v2 stays own-channel only
  (`broadcaster_user_id == moderator_user_id == own id`).
- No optimistic insert on send (existing rule); mod actions apply local
  tombstone/purge immediately and reconcile with EventSub via `messageId`
  dedup.
- All Helix services take an injectable `http.Client` (existing test
  pattern); no real HTTP in unit tests.
- After any MobX store change: regenerate —
  `flutter pub run build_runner build --delete-conflicting-outputs`.
- Commit per task (small, logically scoped).

## Existing seams (verified against code)

- `TwitchChatStore` (`lib/stores/views/twitch_chat.dart`): DI constructor
  with `_eventSubFactory`, `_badgeStoreResolver`, `_emoteStoreResolver`,
  `_userEmoteStoreResolver`, `_messageService`; `connectChat()` at :349,
  `sendChatMessage()` at :454, scope gates `canReadModeration` /
  `canReadEmotes` pattern.
- `TwitchEventSubService._createSubscriptions`
  (`lib/utils/twitch/twitch_eventsub_service.dart:263`): conditions built as
  `{'broadcaster_user_id': userId, 'user_id': userId}`; moderate sub
  (:291-296) both slots = userId; created ids tracked in `_subscriptionIds`.
- `TwitchMessageService.sendChatMessage({accessToken, userId, message})`
  (`lib/utils/twitch/twitch_message_service.dart:18`): posts
  `broadcaster_id: userId, sender_id: userId`.
- Settings keys: enum + `.name` string map in
  `lib/types/enums/settings_keys.dart` (map at :219); read via
  `Hive.box(HiveKeys.Settings.name).get(SettingsKeys.X.name, defaultValue:)`.
- `UsernameDropdown`
  (`lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/username_dropdown.dart`):
  the idiom to mirror for the native channel dropdown; native branch of
  `ChatUsernameBar` currently hides it.
- Tests: `test/chat/` — service tests use injectable `http.Client` fakes;
  store tests use the DI constructor seams; widget tests pump the widget
  with a mocked store.

---

### Task 1: Scopes, `TwitchChannelRef` model, settings keys

**Files:**
- Modify: `lib/utils/twitch/twitch_auth_service.dart:27-36`
- Create: `lib/types/classes/twitch/twitch_channel_ref.dart`
- Modify: `lib/types/enums/settings_keys.dart` (enum + name map :219)
- Test: `test/chat/twitch_channel_ref_test.dart`

**Produces:**
- `kTwitchChatScopes` extended with the 4 scopes from Global Constraints
  (doc comment updated: discovery + mod actions).
- `class TwitchChannelRef { final String id; final String login; final
  String displayName; final DateTime addedAt; }` with
  `fromJson(Map<String, Object?>)` / `toJson()` and `==`/`hashCode` on `id`.
- `SettingsKeys.NativeChatChannels` (`[List<dynamic>]` — json maps) and
  `SettingsKeys.SelectedNativeChatChannelId` (`[String?]`), each with a
  doc-comment line and a kebab-case name-map entry
  (`'native-chat-channels'`, `'selected-native-chat-channel-id'`).

**Tests:** scope list contains the 4 new entries; `TwitchChannelRef` json
round-trip; equality by id. Commit:
`feat(chat): multi-chat scopes + channel ref model + settings keys`

---

### Task 2: `TwitchChannelService` — search / moderated / followed

**Files:**
- Create: `lib/utils/twitch/twitch_channel_service.dart`
- Create: `lib/types/classes/twitch/twitch_channel_search_result.dart`
- Test: `test/chat/twitch_channel_service_test.dart`

**Produces (all with injectable `http.Client`, throwing
`TwitchAuthException` with `statusCode` on non-200, mirroring
`TwitchMessageService` style):**
- `Future<List<TwitchChannelSearchResult>> searchChannels({required String
  accessToken, required String query})` → GET
  `$kTwitchHelixBase/search/channels?query=…&first=20`. Result DTO:
  `{id, login, displayName, followerCount, isLive}`.
- `Future<List<TwitchChannelRef>> getModeratedChannels({required String
  accessToken, required String userId})` → GET
  `$kTwitchHelixBase/moderation/channels?user_id=…&first=100` (paginate
  once via `pagination.cursor` if present — single extra page is enough).
- `Future<List<TwitchChannelRef>> getFollowedChannels({required String
  accessToken, required String userId})` → GET
  `$kTwitchHelixBase/channels/followed?user_id=…&first=100` (same paging
  rule).

**Tests:** URL/headers/params correct; json parsing incl. empty `data`;
non-200 throws with status; cursor page followed. Commit:
`feat(chat): channel discovery service — search/moderated/followed`

---

### Task 3: `TwitchModerationService` — delete / timeout / ban

**Files:**
- Create: `lib/utils/twitch/twitch_moderation_service.dart`
- Test: `test/chat/twitch_moderation_service_test.dart`

**Produces:**
- `Future<void> deleteChatMessage({required String accessToken, required
  String broadcasterId, required String moderatorId, required String
  messageId})` → DELETE
  `$kTwitchHelixBase/moderation/chat?broadcaster_id=…&moderator_id=…&message_id=…`
  (204 expected).
- `Future<void> banUser({required String accessToken, required String
  broadcasterId, required String moderatorId, required String userId,
  int? durationSeconds})` → POST `$kTwitchHelixBase/moderation/bans`,
  body `{'data': {'user_id': …, 'duration': …?}}` — `durationSeconds ==
  null` means permanent ban (key omitted). 200 expected.
- Both throw `TwitchAuthException(statusCode:)` otherwise.

**Tests:** exact method/URL/body incl. omitted `duration`; 204/200
success; error statuses throw. Commit:
`feat(chat): moderation service — delete/timeout/ban`

---

### Task 4: `TwitchMessageService` — explicit `broadcasterId`

**Files:**
- Modify: `lib/utils/twitch/twitch_message_service.dart:18-34`
- Modify: `lib/stores/views/twitch_chat.dart` (call site :468)
- Test: `test/chat/twitch_message_service_test.dart`

**Change:** signature becomes `sendChatMessage({required String accessToken,
required String senderId, required String broadcasterId, required String
message})`; body posts `broadcaster_id: broadcasterId, sender_id:
senderId`. Store call site passes both as `user.id` for now (behavior
unchanged until Task 7). Update the class doc comment ("into their own
channel" → "into [broadcasterId]'s channel").

**Tests:** existing cases updated to the new signature + one asserting the
two ids can differ. Commit:
`feat(chat): message service — explicit broadcaster id`

---

### Task 5: EventSub service — channel parameterization + `switchChannel`

**Files:**
- Modify: `lib/utils/twitch/twitch_eventsub_service.dart`
- Test: `test/chat/twitch_eventsub_service_test.dart`

**Changes:**
- `connect({required String accessToken, required String userId, required
  String broadcasterId, bool includeModeration = false})` — stores
  `_userId` (session user, keepalive/moderate condition) and
  `_broadcasterId` (chat channel).
- `_createSubscriptions` (:263): chat/lifecycle conditions become
  `{'broadcaster_user_id': _broadcasterId, 'user_id': _userId}`; the
  moderate sub (:291) keeps `broadcaster_user_id == moderator_user_id ==
  _userId` (own channel only).
- New `Future<void> switchChannel(String broadcasterId)`: DELETE each id
  in `_subscriptionIds` (best-effort, `DELETE
  $kTwitchHelixBase/eventsub/subscriptions?id=…`, 204), then set
  `_broadcasterId` and re-run the chat/lifecycle subs **on the same
  session** (moderate sub is not re-created — it's own-channel and was
  never channel-scoped). If the session resumption path
  (`_handleWelcome`) re-creates subs, it uses the current `_broadcasterId`.
- Track which sub ids are channel-scoped vs the moderate sub so
  `switchChannel` only deletes/re-creates channel-scoped ones (e.g. keep
  `_moderateSubscriptionId` separate).

**Tests:** conditions carry distinct broadcaster/user ids; moderate sub
unchanged; `switchChannel` issues DELETEs for channel-scoped ids then
POSTs with the new broadcaster on the same `session_id`; resume after
switch uses the new broadcaster. Commit:
`feat(chat): eventsub — per-channel broadcaster + same-session switch`

---

### Task 6: Catalog stores — per-broadcaster keying

**Files:**
- Modify: `lib/stores/views/twitch_badges.dart`
- Modify: `lib/stores/views/third_party_emotes.dart`
- Modify: `lib/stores/views/twitch_emotes.dart` (+ stale comment :49)
- Tests: `test/chat/twitch_badge_store_test.dart`,
  `test/chat/third_party_emote_store_test.dart`,
  `test/chat/twitch_emote_store_test.dart`

**Changes:**
- `TwitchBadgeStore`: channel badge catalog keyed by broadcaster —
  `Map<String, …>` lookups take a `broadcasterId` at the read site
  (badge resolution call sites updated; global badges unchanged).
- `ThirdPartyEmoteStore`: same per-broadcaster keying for channel emote
  sets; `fetch({broadcasterId})` writes only that broadcaster's slot.
- `TwitchEmoteStore.fetch({required String accessToken, required String
  userId, required String broadcasterId})` — passes `broadcasterId`
  through to `TwitchEmoteService.fetchUserEmotes` (already accepts it);
  replace the "userId doubles as broadcasterId" comment with the
  multi-channel rationale.
- Read-side call sites (chat row rendering, emote picker) pass the
  store's current effective broadcaster.

**Tests:** two broadcasters' catalogs coexist without overwrite; lookups
fall back cleanly for an unfetched broadcaster. Commit:
`feat(chat): per-broadcaster badge/emote catalogs`

---

### Task 7: `TwitchChatStore` — multi-channel core

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart` (+ `.g.dart` regen)
- Test: `test/chat/twitch_chat_store_test.dart`

**Consumes:** Tasks 1–6 interfaces.

**Produces:**
- Observables: `ObservableList<TwitchChannelRef> channels`,
  `String? selectedChannelId`, `ObservableSet<String>
  moderatedChannelIds`.
- `String get effectiveBroadcasterId => selectedChannelId ?? user!.id;`
- `bool get canModerateSelectedChannel => selectedChannelId == null ||
  moderatedChannelIds.contains(selectedChannelId);` (own channel =
  implicit mod; also requires the manage-scopes on the token — mirror the
  `canReadModeration` pattern: `canModerateChats` scope gate).
- `@action Future<void> addChannel(TwitchChannelRef ref)` — dedupe by id,
  persist to `SettingsKeys.NativeChatChannels` (json list), then
  `selectChannel(ref.id)` (adding expresses intent to view).
- `@action Future<void> removeChannel(String id)` — drop from list +
  persist; if it was selected, `selectChannel(null)`; drop its buffer.
- `@action Future<void> selectChannel(String? id)`:
  1. No-op if unchanged or not logged in.
  2. Snapshot `messages` + tombstone state + `systemNotices` into
     `_channelBuffers[effectiveBroadcasterId]`.
  3. `chatConnection = connecting`; `await
     _eventSub.switchChannel(id ?? user!.id)`.
  4. Replace live list with `_channelBuffers[newId]` (or empty).
  5. Fire-and-forget catalog refetch for the new broadcaster (same
     guarded pattern as `connectChat` :375-428).
- `connectChat()` passes `broadcasterId: effectiveBroadcasterId` and
  re-fetches catalogs for it (:369, :379, :401, :420 call sites).
- `sendChatMessage` passes `senderId: user.id, broadcasterId:
  effectiveBroadcasterId`.
- Login: after own-user fetch, if token has
  `user:read:moderated_channels`, fire-and-forget
  `getModeratedChannels` → `moderatedChannelIds` (failure = empty set,
  logged).
- `messageId` dedup: track recently-applied delete/purge ids (small
  bounded set); `applyMessageDelete` / `applyModerationDelete` /
  `applyClearUserMessages` skip already-applied ids (fixes the duplicate
  double-banner/tombstone class).
- Init: load `channels` + `selectedChannelId` from settings box (tolerate
  missing/garbage → empty/null); persist `selectedChannelId` on change.

**Tests:** add/remove/select flows incl. persistence round-trip; buffer
save/restore on switch; dedup skips repeat deletes; gating matrix (own /
moderated / not, pre-upgrade token); send uses effective broadcaster.
Commit: `feat(chat): store multi-channel core — switch, buffers, gating`

---

### Task 8: UI — channel dropdown (native chat bar branch)

**Files:**
- Create:
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/native_channel_dropdown.dart`
- Modify:
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_username_bar.dart`
  (native branch)
- Test: `test/chat/native_channel_dropdown_test.dart`

**Behavior:** dropdown styled like `UsernameDropdown`; items = own channel
first (display name + "You" marker), then `channels` (display name,
shield icon when `moderatedChannelIds` contains the id); value =
`selectedChannelId` (own = null); `onChanged` →
`store.selectChannel`. Long-press a non-own item → confirm dialog →
`store.removeChannel` (fallback to own when removing the selected).
Bottom item: "Add chat…" (opens the Task 9 sheet). Observer-wired (MobX
`Observer`), disabled while `chatConnection == connecting`.

**Tests:** order/own-marker/shields; select calls store; remove confirm +
fallback; add entry opens sheet; disabled during switch. Commit:
`feat(chat): native channel dropdown in chat bar`

---

### Task 9: UI — add-chat picker sheet

**Files:**
- Create:
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/add_chat_sheet.dart`
- Test: `test/chat/add_chat_sheet_test.dart`

**Behavior:** bottom sheet; debounced (~300 ms) search field →
`TwitchChannelService.searchChannels` results (display name, `@login`,
follower count, live dot); empty query shows "Channels you moderate" and
"Channels you follow" sections (from Task 2 calls, live first for
follows). Each section fails independently: inline error + retry.
Already-added ids render checked/disabled. Tap →
`store.addChannel(ref)` (which switches — Task 7) and close. Sections
hidden when the token lacks the matching scope; a re-login CTA (existing
pattern) sits at the bottom when any capability is locked.

**Tests:** debounce; results render + tap adds; duplicate disabled;
per-section error/retry; scope-gated sections hidden. Commit:
`feat(chat): add-chat picker sheet — search/moderated/followed`

---

### Task 10: UI + store — mod action sheet

**Files:**
- Modify:
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart`
  (tap target for live messages)
- Create:
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/mod_action_sheet.dart`
- Modify: `lib/stores/views/twitch_chat.dart`
- Tests: `test/chat/mod_action_sheet_test.dart` +
  `twitch_chat_store_test.dart` additions

**Behavior:** tapping a *live* message when
`store.canModerateSelectedChannel` opens the sheet: **Delete message** /
**Timeout…** (presets 10 min, 1 hour, 24 hours) / **Ban**. Store actions:
- `deleteMessage(ChatMessageEvent e)` → service → local tombstone via the
  Task 7 dedup path.
- `timeoutUser(targetUserId, durationSeconds)` / `banUser(targetUserId)` →
  service → purge that user's messages to tombstones locally.
Failures → snackbar, no local state change. Tombstone tap keeps its
actor-reveal meaning; non-mod channels get no sheet.

**Tests:** sheet only in modded channels; each action hits the service
with exact params; local tombstone/purge applied; failure leaves state
untouched; EventSub echo doesn't double-apply. Commit:
`feat(chat): mod actions — delete/timeout/ban with local reconcile`

---

### Task 11: Wrap-up — gates + docs + dogfood handoff

- `flutter pub run build_runner build --delete-conflicting-outputs`
- `flutter analyze` — 0 errors (6 pre-existing warnings tolerated)
- `flutter test test/chat/ test/websocket/ test/persistence/` — all green
- Update `docs/changelog-agent.md` (wave entry) and reset
  `docs/session-handoff.md` (multi-chat shipped; dogfood checklist from
  the spec §6 carried over as the open item; actor-reveal dogfood marked
  done — it passed before this wave)
- Commit: `docs: multi-chat wrap-up — changelog + handoff`

---

## Self-review notes

- Spec coverage: §1→Task 1/7, §2→Task 8/9, §3→Tasks 4/5/6/7, §4→Tasks
  1/2/3/7/10, §5→per-task error handling, §6→per-task tests + Task 11
  dogfood. Out-of-scope items untouched.
- Type consistency: `TwitchChannelRef`, `effectiveBroadcasterId`,
  `selectChannel(String?)`, `addChannel/removeChannel`,
  `canModerateSelectedChannel`, service signatures are used identically
  across tasks.
- Deliberate refinement beyond spec: adding a channel switches to it
  (spec was silent); removal affordance is long-press on the dropdown row
  (as spec §2).
