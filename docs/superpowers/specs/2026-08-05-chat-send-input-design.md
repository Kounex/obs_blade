# Native Twitch chat — send input (design)

Date: 2026-08-05 · Status: approved design (pre-plan) · Track: native Twitch chat, Phase 4 (send input)

## Context

The native Twitch chat is read-only today. The chat window (Phase 3) was
designed with a bottom dock slot reserved for exactly this: an input field
so the streamer can chat natively from the app. Sending uses Twitch's Helix
`Send Chat Message` endpoint, which requires the `user:write:chat` scope —
the current device-flow login only requests `user:read:chat`.

Dock shape was picked from browser mockups (visual companion,
`.superpowers/brainstorm/`): **pill text field + circular send button**
(option A — no character counter). Rollout strategy: **silent scope
upgrade** (nobody is logged out; the input appears once the account's token
has write scope).

## Decisions (from brainstorming)

- **Silent upgrade.** Add `user:write:chat` to the login scope request.
  The input dock appears only when the stored token actually carries the
  scope; pre-existing logins see a read-only hint strip ("Re-login to
  chat") until their next login. No forced logout.
- **Input slot on the window.** `NativeChatWindow` gains an optional
  `input` slot; the dock is a generic `NativeChatInput` widget (plain
  params, no Twitch types) — the same reuse seam as the window for a
  future native YouTube engine. No engine-interface abstraction (YAGNI).
- **No optimistic insert.** Our EventSub subscription echoes our own
  messages back (Twitch parses emotes in them, fragments included), so the
  sent message renders through the normal path. `messageId` dedup stays
  out of scope.
- **Drop reasons are surfaced.** Helix can return 200 with
  `is_sent: false` + `drop_reason` (AutoMod, duplicates, …) — shown as a
  transient inline error in the dock, never a silent no-op.
- **No character counter** (option A over C); a hard 500-char `maxLength`
  cap on the field instead.
- **Failed sends keep the text** in the field for retry; success clears it.

## Verified API facts

- `POST https://api.twitch.tv/helix/chat/messages` with a **user access
  token** carrying `user:write:chat`. (The extra `user:bot`/`channel:bot`
  requirements apply to app access tokens only — not our device-flow user
  token.) Rate limit is per chatting user, IRC-parity — irrelevant at
  human typing speed.
- Body: `broadcaster_id` (the chat room — our own channel id),
  `sender_id` (same user id), `message` (string, ≤500 chars).
- 200 response: `{data: [{message_id, is_sent, drop_reason}]}` —
  `is_sent: false` means Twitch accepted but dropped the message;
  `drop_reason` is then an OBJECT `{code, message}` (`code` machine
  string, `message` Twitch's own human text), `null` when sent.
  (Corrected post-review — this spec originally claimed a plain machine
  string; modeling it as `String?` made every real drop throw at parse.)
- Non-200: 400 (invalid/missing fields, message too long), 401 (token
  invalid/missing scope), 403 (sender banned from the channel — impossible
  in own channel, but Twitch incidents happen), 429 (rate limited), 5xx.
- The scope list is one const: `kTwitchChatScopes`
  (`lib/utils/twitch/twitch_auth_service.dart:14`, used at `:64` in the
  device-code request). Persisted scopes live in `TwitchAuth.scopes`
  (`_persistAuth` stores `token.scope` — device-flow tokens echo the
  granted scopes).
- Own messages echo via the existing `channel.chat.message` subscription
  (broadcaster = sender = self), with full emote fragments.

## Architecture

### 1. Scope request (one line)

`kTwitchChatScopes` becomes `['user:read:chat', 'user:write:chat']`.
Existing stored sessions are untouched (silent upgrade).

### 2. `TwitchMessageService` — Helix send

New file `lib/utils/twitch/twitch_message_service.dart`, mirroring
`TwitchBadgeService` (`http.Client` injectable for tests, reuses
`TwitchAuthService.helixHeaders` + `kTwitchHelixBase`, throws
`TwitchAuthException(statusCode)` on non-200):

- `Future<TwitchSendResult> sendChatMessage({required String accessToken,
  required String userId, required String message})` — `userId` fills both
  `broadcaster_id` and `sender_id` (own channel only, today).

### 3. DTO

New file `lib/types/classes/twitch/twitch_send_result.dart` (freezed,
same pattern as `twitch_chat_badges.dart`):

- `TwitchSendResult { String messageId, bool isSent, String? dropReason }`
  — `@JsonKey` pins (`message_id`, `is_sent`, `drop_reason`), envelope
  unwrap of Helix's `{data: [...]}` (first element).

### 4. `TwitchChatStore` — gate + send action

- `bool get canWriteChat` — plain getter (not `@computed`):
  `_authBox.get(TwitchAuth.kBoxKey)?.scopes.contains('user:write:chat') ??
  false`. Deliberately non-reactive: scopes change only at login/logout,
  and those transitions already flip the `user`/`authState` observables
  that rebuild the widget's `Observer`, so the getter is re-read exactly
  when it can change. Documented as such in the code.
- `@observable bool sendingChat = false` — in-flight guard + UI spinner.
- `@observable String? sendChatError` — transient; set on failure, cleared
  on the next send attempt.
- `Future<bool> sendChatMessage(String text)` — guards: logged in,
  `canWriteChat`, trimmed text non-empty, not `sendingChat`. Sets
  `sendingChat`, clears `sendChatError`, token via `_validAccessToken()`,
  service call. `is_sent: true` → return `true`. `is_sent: false` →
  `sendChatError = 'Message not delivered${_dropReasonText}'`, return
  `false`. Exception → `sendChatError = 'Could not send — try again'`,
  return `false`. Always resets `sendingChat` in `finally`. Never throws
  to the UI. Drop-reason text: map the common ones
  (`automod_blocked`/`automod_held` → "held by AutoMod", `duplicate` →
  "duplicate message", `rate_limited` → "sending too fast") with a generic
  fallback of the raw reason.
- Service resolved through a constructor seam (same injectable pattern as
  `eventSubFactory` / `badgeStoreResolver`) so unit tests substitute a
  fake.
- No `DashboardStore` changes; no Hive schema changes (scopes already
  persisted).

### 5. `NativeChatWindow` — input slot

- New optional `Widget? input` param. When non-null: rendered below the
  `Expanded(child)`, separated by a `BaseDivider`, inside the pane's clip.
  Layout for a future multiline variant stays a simple bottom slot.
- The window itself stays engine-agnostic — the slot takes any widget.

### 6. `NativeChatInput` — the dock widget

New file
`lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart`
(StatefulWidget — owns the `TextEditingController`/`FocusNode`):

- Params: `canSend` (bool), `inFlight` (bool), `errorText` (`String?`),
  `onSend` (`Future<bool> Function(String)` — widget clears the field when
  it completes `true`), `onRelogin` (`VoidCallback`), all plain types.
- **Ready state** (`canSend`): row at pane bottom — pill `TextField`
  (single-line, `TextInputAction.send`, submit == send, `maxLength: 500`
  with the counter hidden via `counterText: ''`, fill = the lightened
  control idiom, `AppRadius.pill`) + circular send button (brand color,
  34pt visual inside a ≥44pt `Pressable` target, send icon; `inFlight` →
  small adaptive spinner, field + button disabled). Error line
  (`errorText != null`): small red text row above the dock, transient by
  store semantics.
- **Read-only state** (`!canSend`): the lock strip — lock icon +
  "Logged in read-only" + right-aligned "Re-login to chat" `Pressable`
  (≥44pt) firing `onRelogin`. No text field.
- Doc comments per house style; tokens (`AppSpacing`/`AppRadius`/
  `AppMotion`); `Pressable` everywhere tappable.

### 7. Wiring in `stream_chat.dart`

- The native branch passes `input:` to `NativeChatWindow` only when
  `loggedIn`: `NativeChatInput(canSend: store.canWriteChat, inFlight:
  store.sendingChat, errorText: store.sendChatError, onSend:
  store.sendChatMessage, onRelogin: () => startTwitchLogin(context))`.
- Same `Observer` — `canWriteChat`/`sendingChat`/`sendChatError` are all
  observable reads inside the builder.

## Error handling & edge cases

- **Read-only token mid-session** (logged in pre-upgrade): dock shows the
  hint strip; nothing else changes. After re-login, `canWriteChat` flips
  live (Observer).
- **Drop without error (200, `is_sent: false`)** — transient error line;
  field text kept; no echo arrives (nothing renders) — consistent.
- **401 mid-session** (token revoked between refresh window and send):
  `TwitchAuthException(401)` surfaces as the generic error line; the
  existing EventSub revocation path handles session state independently.
  No special handling beyond the error line (scope of this phase).
- **429 / typing-fast spam:** error line "sending too fast"; field text
  kept; no client-side rate scheduling.
- **Empty/whitespace input:** guarded (trim), send disabled.
- **500-char cap:** hard `maxLength` — the 400 "message too long" path is
  unreachable from our UI but still maps to the generic error line.
- **Reconnect/offline while typing:** text stays in the field (widget-
  owned controller); send while not `live` attempts normally (Helix works
  without an EventSub session) — the echo renders on reconnect. Acceptable
  and simple; no extra gating.
- **Sheet/status interplay:** none — the status row and connection sheet
  are untouched.

## Testing

- **Unit** (`test/chat/`):
  - `TwitchSendResult` parsing: sent, dropped (`drop_reason`), envelope
    unwrap; service throws `TwitchAuthException` with `statusCode` on
    non-200 (mirroring badge-service tests).
  - `TwitchChatStore.sendChatMessage`: guards (logged out, no scope,
    empty, already sending), success path (service fake, `true`,
    `sendingChat` toggles, error cleared), dropped path (`false` +
    mapped error text), exception path (`false` + generic error).
  - `canWriteChat` from persisted scopes (read-only token → false,
    upgraded token → true).
- **Widget**:
  - `NativeChatInput`: ready state renders field + send button; read-only
    renders the lock strip and fires `onRelogin`; send submits trimmed
    text and clears on `true`, keeps on `false`; `inFlight` disables +
    shows spinner; error line renders `errorText`; 500-cap enforced.
  - `NativeChatWindow` renders the `input` slot below the content when
    provided (layout smoke).
- Gates: `flutter analyze` 0 errors + the 6 pre-existing warnings; full
  `flutter test` green (baseline 145).

## Out of scope (explicit)

- Reply threads, `/announce`, slash commands, `/me`.
- AutoMod review queue (allow/deny held messages).
- Multi-channel sending (chat room == own channel).
- Character counter UI, client-side rate scheduling, optimistic insert,
  `messageId` dedup.
- Entitlement gating (the availability gate track is separate).
- Native YouTube engine (seam reused, engine not built).

## Docs hygiene

No credentials, user ids, or LAN details in code, tests, or docs; the
public Twitch client id reuse follows the existing `kTwitchClientId`
precedent.
