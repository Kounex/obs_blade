# Plan — native YouTube chat engine (2026-09-03)

**Tier: L** — multi-subsystem (new platform across types/services/store/UI/persistence),
precedent: chat waves. Feasibility + sources: [`../../youtube-native-chat-audit.md`](../youtube-native-chat-audit.md).
Named constraints: `docs/superpowers/plan-defect-checklist.md` §2/§3 apply to every
task (verify shapes against repo, codegen regen after last annotated edit, `.g.dart`
in commit lists, mutation tests positive-before/negative-after, no vacuous asserts).

## Design decisions (fixed — implementers do not re-litigate)

1. **Read transport: REST polling** (`liveChatMessages.list`), honoring
   `pollingIntervalMillis`, page-token resume, stop on `offlineAt`/`chatEndedEvent`.
   gRPC `streamList` is **spike-tool only** this wave; in-app gRPC is a follow-up
   gated on the quota measurement.
2. **Auth split:**
   - **Read** requires a YouTube Data **API key**: user's own (BYO, the power-user
     path) stored in settings key `YouTubeApiKey`; an app-owned key may later fill
     the constant `kYouTubeApiKey` (empty string + comment this wave).
   - **Write/mod** requires **Google OAuth device flow** (RFC 8628-style:
     `https://oauth2.googleapis.com/device/code` + token polling), scope
     `https://www.googleapis.com/auth/youtube`. Client id from settings key
     `YouTubeOAuthClientId`, falling back to constant `kYouTubeOAuthClientId`
     (empty + comment). Mirror `TwitchAuthService` shape (injectable
     `http.Client`, `YouTubeAuthException`).
3. **Persistence:** new Hive model `YouTubeAuth` (`typeId: TypeIDs.YouTubeAuth = 15`
   — 0–14 taken in `lib/models/type_ids.dart`), single-record box key `'current'`,
   fields mirroring `TwitchAuth` minus Twitch user fields plus `channelTitle`.
   New settings keys: `YouTubeApiKey`, `YouTubeOAuthClientId` (String),
   `SelectedYouTubeNativeChannelId` (String, mirrors Twitch's native channel
   selection). No chat-content persistence (session buffers only, same as Twitch).
4. **Channels/multi-chat:** the existing `YouTubeUsernames` settings entry
   (`SettingsKeys.YouTubeUsernames`, `Map<String, String>` label → bare video id;
   legacy values may be full URLs — always parse via `extractYouTubeVideoId`,
   `lib/utils/youtube_video_id.dart`) is the channel list. Native engine resolves
   each id → `liveStreamingDetails.activeLiveChatId` (`videos.list`, 1 unit) on
   select; video with no active chat = "not live" state. **Known caveat:**
   entries are per-video, not per-channel — a streamer's next stream has a new
   video id and the entry goes stale ("not live") until re-edited; there is no
   stable channel-key lookup with the official API. Surface this in the setup
   sheet copy, don't try to fix it. `SelectedYouTubeNativeChannelId` stores the
   **label** (map key — stable across re-edits), not the video id.
5. **Message model:** `YouTubeChatMessage` freezed, `fromJson` against the
   `liveChatMessage` REST resource. Type enum: `textMessage`, `superChat`,
   `superSticker`, `newSponsor`, `memberMilestone`, `membershipGifting`,
   `giftMembershipReceived`, `poll`, `userBanned`, `tombstone`,
   `sponsorOnlyModeStarted`, `sponsorOnlyModeEnded`, `chatEnded`, `unknown`
   (forward-compat default). Keeps: id, authorChannelId, authorName,
   authorProfileImageUrl, displayText, publishedAt, badge booleans
   (owner/mod/sponsor/verified), superChatDetails {amountDisplayString, tier,
   userComment}, superSticker altText, poll details, ban details
   (type/duration/acting mod id), local `isTombstoned` flag.
6. **Lifecycle/moderation:** `tombstone` messages mark the matching buffered
   message tombstoned (dim + marker — same UX as Twitch); `userBannedEvent`
   purges the banned author's buffered messages; echo dedup via applied-keys set
   (same pattern as `TwitchChatStore._appliedModerationKeys`).
7. **Mod capability gating:** YouTube has no cheap "am I a mod" lookup
   (`liveChatModerators.list` is owner-only). Mod action rows show when signed
   in; a 403/`forbidden` surfaces as an error toast. Do not invent a heuristic.
8. **UI:** extend `nativeChatAvailableFor` to `ChatType.YouTube`;
   `stream_chat.dart` native branch dispatches per platform. New widgets mirror
   the Twitch set: `native_youtube_chat_view.dart`,
   `youtube_chat_message_row.dart`, `youtube_account_control.dart`,
   `youtube_device_code_dialog.dart`, `youtube_setup_sheet.dart` (API key entry
   + validate probe + sign-in CTA). Badges render as icons (crown/wrench/
   member/check) — no artwork exists in the API. Super Chat renders as a
   tier-colored card (fixed tier→color map). Reuse `NativeChatWindow`,
   `NativeChatInput`, chrome, appearance settings as-is. `SelectedChatEngine`
   stays global (user intent carries across platforms).
9. **WebView fallback untouched.** No changes to `_buildLegacyChatStack` or the
   YouTube embed path.

## Tasks

### Task 1 — spike tool `tool/youtube_spike/`
Standalone Dart package (own pubspec: `grpc`, `protobuf`, `http`, `args`).
`bin/youtube_spike.dart --api-key K (--video-id V | --live-chat-id L)
--mode poll|stream|both --duration-minutes N`:
- resolves `activeLiveChatId` via `videos.list` when given `--video-id`;
- poll mode: `liveChatMessages.list` loop honoring `pollingIntervalMillis`;
  logs calls, units (×5), messages, interval drift;
- stream mode: gRPC `V3DataLiveChatMessageService.StreamList` with
  `x-goog-api-key`, resume via last `nextPageToken`, reconnect/backoff on EOF;
  logs connection lifetimes, EOF count, messages;
- `tool/youtube_spike/README.md`: protoc setup (`stream_list.proto` fetch +
  `protoc --dart_out`), run examples, and the **quota measurement protocol**
  (GCP console quota snapshot before/after a ≥30-min run on a busy chat,
  compute units/connection-hour, record in the audit doc).
- Generated pb files are gitignored in the tool; setup script regenerates.
- Commit: `tool(youtube): quota spike tool for live chat read paths`.

### Task 2 — core layer: types + services + auth model
- `lib/types/classes/youtube/youtube_chat_message.dart` (+ freezed/json codegen).
- `lib/utils/youtube/youtube_auth_service.dart` — device flow start/poll,
  refresh, revoke; settings-client-id → constant fallback. Mirror the exact
  `TwitchAuthService` shape: ctor `({http.Client? client, Future<void>
  Function(Duration)? sleep})`, `YouTubeAuthException(message, {cause,
  statusCode})`.
- `lib/utils/youtube/youtube_live_chat_service.dart` — `listMessages`
  (apiKey or bearer), `insert`, `delete`, `ban`/`unban`,
  `getActiveLiveChatId(videoId)`; typed errors (quota, forbidden, chatEnded).
- `lib/models/youtube_auth.dart` + `TypeIDs.YouTubeAuth = 15`; **manual**
  `Hive.registerAdapter(YouTubeAuthAdapter())` in `lib/main.dart`
  (`_initializeHive` — adapters are registered manually there, the generated
  `lib/hive_registrar.g.dart` is NOT used by the app; regen it anyway to keep
  it current); new `HiveKeys.YouTubeAuth` box-name entry in
  `lib/types/enums/hive_keys.dart`.
- `lib/types/enums/settings_keys.dart` (NOT `lib/utils/`): `YouTubeApiKey`,
  `YouTubeOAuthClientId`, `SelectedYouTubeNativeChannelId` — follow the
  file's doc-comment type-tag convention and add the mandatory `name` map
  entries.
- `data_management.dart`: the "YouTube Chats" clear must also delete the
  `YouTubeAuth` box and the three new settings keys (precedent: "Twitch
  Chats" clear at `data_management.dart:160`).
- Tests (`test/chat/`): message JSON parsing fixtures under
  `test/chat/fixtures/youtube/` (text, superChat, superSticker,
  memberMilestone, gifting, poll, userBanned, tombstone); auth service
  device-flow + refresh with fake `http.Client`; live chat service parsing +
  error mapping with fake client. **Plus** a persistence round-trip test
  `test/persistence/youtube_auth_persistence_test.dart` (precedent:
  `twitch_auth_persistence_test.dart`) — requires guarded adapter
  registration in `test/persistence/support/hive_test_harness.dart`.
- Codegen AFTER all annotated edits (§3); commit file list:
  the above + `lib/models/youtube_auth.g.dart`,
  `lib/types/classes/youtube/youtube_chat_message.{freezed,g}.dart`,
  regenerated `lib/hive_registrar.g.dart`.
- Commit: `feat(chat): youtube core layer — types, auth + live chat services, hive model`.

### Task 3 — `YouTubeChatStore`
- `lib/stores/views/youtube_chat.dart` mirroring `TwitchChatStore` structure:
  auth state machine, connection state, channels from `YouTubeUsernames`,
  per-channel buffer swap on select (pattern: `TwitchChatStore.selectChannel`,
  `lib/stores/views/twitch_chat.dart:983-1005`; superseded-flow guard pattern:
  `_loginFlow` int at lines 134-136), adaptive poll loop honoring
  `pollingIntervalMillis`, send (sign-in gated), delete/timeout/ban with
  optimistic local reconcile + echo dedup (`_appliedModerationKeys` pattern,
  lines 281-287/1091-1096), tombstone/ban lifecycle,
  `canRead`/`canWrite`/`isConfigured` getters. Persist
  `SelectedYouTubeNativeChannelId` = the **label** (map key).
- DI: register store + open `YouTubeAuth` box in `lib/main.dart` (mirror
  lines 96-101 store/dispose and 163-166 box open); dispose hook.
- Codegen AFTER all annotated edits (§3); commit file list includes the
  generated `lib/stores/views/youtube_chat.g.dart`.
- Tests (`test/chat/youtube_chat_store_test.dart`): same harness style as
  `twitch_chat_store_test.dart` (real temp-dir Hive via `HiveTestHarness`,
  fakes subclassing the real services — new
  `test/chat/support/fake_youtube_services.dart`, store injected via ctor,
  no GetIt): buffering across poll pages, channel switch buffer swap, send
  gate (signed-out → read-only), tombstone marks (positive-before/
  negative-after), ban purge, dedup of echoed moderation.
- Commit: `feat(chat): youtube chat store — polling, multi-video buffers, mod actions`.

### Task 4 — UI + configuration UX
- `chat_engine.dart` gate += YouTube; **`test/chat/chat_engine_test.dart:21`
  asserts YouTube isFalse — update it** (assertion flips to isTrue).
- `stream_chat.dart` native branch (lines 267-351, Twitch-hardcoded) →
  per-platform dispatch; `_buildLegacyChatStack` (line 366) untouched.
- `native_youtube_chat_view.dart`, `youtube_chat_message_row.dart`
  (icon badges, Super Chat tier card, sticker alt text, poll/gift/milestone
  notice rows, tombstones), `youtube_account_control.dart`,
  `youtube_device_code_dialog.dart` (mirror `twitch_device_code_dialog.dart`
  + `startTwitchLogin` entry-point pattern), `youtube_setup_sheet.dart`
  (API key field + "Test key" probe via `videos.list`, sign-in CTA,
  Google Cloud Console setup steps, per-video staleness caveat copy).
- `NativeChatWindow` reuse: omit the Twitch-coupled `selfUserId` /
  `userService` params (no self user card for YouTube this wave).
- Chat-bar right cluster (`chat_username_bar.dart:146-193`): platform
  dispatch — Twitch cluster untouched, YouTube gets account control +
  options. Channel dropdown: **fork a YouTube variant** of
  `native_channel_dropdown.dart` (the existing one is Twitch-bound — do not
  generalize it).
- Beta warning (`DontShowYouTubeChatBetaWarning`, shown from
  `chat_type_dropdown.dart:75,89`): suppress when the selected chat engine
  is Native — it warns about the WebView embed, which no longer applies.
- Widget tests: setup sheet validation states, message row variants
  (super chat card, tombstone, badges).
- Commit: `feat(chat): youtube native chat ui — timeline, setup sheet, sign-in`.

### Task 5 — wrap-up
- Full gate once: `bash flutterw test test/chat/ test/websocket/ test/persistence/`
  + `bash flutterw analyze`.
- `docs/changelog-agent.md` entry; AGENTS.md tooling bullet for the spike
  tool; handoff update if session wraps.
- Commit: `docs: youtube native chat wave — changelog, tooling note`.

## Explicitly out of scope
In-app gRPC/streamList, quota-extension application, app-owned API key/OAuth
client rollout, Innertube anything, pinned messages / AutoMod / warn / unban
requests (no API), third-party emotes for YouTube, relay backend.
