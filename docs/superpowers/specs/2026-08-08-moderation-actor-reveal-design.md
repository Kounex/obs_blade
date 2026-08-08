# Design: deleting-moderator reveal via `channel.moderate` v2

**Goal:** Tapping a mod-deleted chat message reveals *who* deleted it
(`<mod> deleted <chatter>'s message`) — the feature designed in
`2026-08-07-deleted-message-content-design.md` that went dormant because
`channel.chat.message_delete` carries no moderator field.

**Architecture:** one new best-effort `channel.moderate` v2 subscription on
the existing EventSub session; its `delete` actions enrich the store's
existing `_deletedMessageActors` map. No new state systems, no persistence,
no UI changes (tap reveal + expansion set already shipped and dormant).

## Twitch facts (verified, no invented payloads)

Sources: [TwitchIO EventSub reference](https://twitchio.dev/en/latest/references/eventsub_subscriptions.html)
and [twitch-rs `moderate.rs`](https://twitch-rs.github.io/twitch_api/src/twitch_api/eventsub/channel/moderate.rs.html).

- `channel.moderate` **v2** requires **all 8** read scopes:
  `moderator:read:blocked_terms`, `moderator:read:chat_settings`,
  `moderator:read:unban_requests`, `moderator:read:banned_users`,
  `moderator:read:chat_messages`, `moderator:read:warnings`,
  `moderator:read:moderators`, `moderator:read:vips`.
  (v1 = same minus `:warnings`; v2 chosen 2026-08-08 — current version,
  one extra read scope makes no consent-screen difference.)
- Condition: `broadcaster_user_id` + `moderator_user_id` (the token user;
  must be a moderator of the channel or the broadcaster — always true here,
  native chat is own-channel only). WebSocket transport, version `'2'`.
- Payload: flat envelope with `action` discriminator; every action field
  present, all but the active one null. Relevant fields:
  `moderator_user_name` (the acting mod) and, for `action == 'delete'`,
  `delete.message_id` / `delete.user_name` (the chatter) / `message_body`.
- The `delete` action is a **superset** of `channel.chat.message_delete`
  (same message id + target, plus the moderator).

## Components

### 1. Auth — `lib/utils/twitch/twitch_auth_service.dart`

`kTwitchChatScopes` gains the 8 `moderator:read:*` scopes. New device-flow
logins consent to them; existing persisted tokens lack them (silent-upgrade
situation, same as `user:write:chat` / `user:read:emotes` before).

### 2. Store gate — `lib/stores/views/twitch_chat.dart`

New plain (deliberately non-reactive) getter, same pattern as
`canReadEmotes`:

```dart
bool get canReadModeration => /* persisted scopes contain all 8 */
```

`connectChat` passes `includeModeration: canReadModeration` to the service.
Pre-upgrade sessions: tombstones keep working, reveal dormant. **No new
CTA** — no natural UI anchor (unlike the input lock strip / picker CTA);
the feature is invisible until it works, and a re-login happens naturally.

### 3. Service — `lib/utils/twitch/twitch_eventsub_service.dart`

- `connect({required String accessToken, required String userId,
  bool includeModeration = false})` — when true, the POST loop appends
  `channel.moderate` (version `'2'`, condition `{broadcaster_user_id,
  moderator_user_id}`) after the four base types.
- Best-effort, identical policy to the lifecycle types: POST failure or
  revocation → `advLog` + degrade (reveal off this session), never chat.
  The existing non-message revocation branch already covers it.
- New optional callback `onModerationDelete(String messageId,
  String moderatorName)`. Notifications parse tolerantly; the callback
  fires only when `action == 'delete'` and `delete.message_id` is present.
  All other actions (timeout, ban, emoteonly, warn, shared_chat_*) are
  parsed-then-ignored.

### 4. DTO — `lib/types/classes/twitch/eventsub/channel_moderate_event.dart` (new)

Freezed, snake rename, `createToJson: false`, matching the file conventions
of `chat_lifecycle_events.dart`:

- `ChannelModerateEvent { required String action, required String
  moderatorUserName, ModerateDeleteAction? delete }`
- `ModerateDeleteAction { required String messageId, String? userName }`

Tolerant by construction: unknown action values and untouched action fields
deserialize fine (they're simply not modeled). Fixture
`test/chat/fixtures/twitch/channel_moderate_delete.json` mirrors the
twitch-rs v2 shape (full null-field envelope, `action: "delete"`); a second
fixture covers a non-delete action (`timeout`).

### 5. Store merge — `lib/stores/views/twitch_chat.dart`

```dart
@action
void applyModerationDelete(String messageId, String actorName)
```

- Message visible → `_deletedMessageIds.add(id)` if new; set
  `_deletedMessageActors[id] = actorName` if unset; bump
  `lifecycleVersion` when either changed.
- Unknown/evicted id → no-op (idempotent, same contract as the existing
  lifecycle actions).
- No pending map: both event orderings converge —
  - `message_delete` first → tombstone; moderate lands later → actor set,
    version bumps, row becomes tappable.
  - moderate first → tombstone + actor; later `message_delete` no-ops.
- Hardens degrade: if the `message_delete` POST failed but moderate
  succeeded, single deletes still tombstone (purge/`/clear` still ride
  their own subs).

### 6. UI — unchanged

`TwitchChatMessageRow` reveal (`isDeleted && deletedActor != null` →
tappable, expansion line) already shipped. Its `deletedActor` doc comment
gets corrected (actor now arrives via `channel.moderate` when the token
carries the scopes).

## Error handling

- Pre-upgrade token (no scopes): subscription never attempted (gate).
- POST 403/failure: logged, reveal degraded — chat + tombstones unaffected.
- Revocation mid-session: existing lifecycle revocation branch logs it.
- Parse failure: existing `_handleNotification` catch logs it.

## Testing

- **DTO:** delete fixture parses (action/mod/messageId/chatter); timeout
  fixture yields `delete == null`; missing `message_id` inside `delete`
  throws.
- **Service:** `includeModeration: true` → 5 POSTs, moderate last, version
  `'2'`, `moderator_user_id` condition; `false` → 4 POSTs (existing test
  unchanged in count assertions); delete notification → callback
  `(messageId, modName)`; non-delete action → no callback; failing moderate
  POST → chat connected, no revocation.
- **Store:** moderate delete tombstones + records actor; message_delete→
  moderate ordering adds actor + bumps version; moderate→message_delete
  ordering stays single tombstone (idempotent); unknown id no-op;
  `connectChat` passes `includeModeration: false` when persisted scopes
  lack the bundle (and `true` when present).
- Gates: full suite green; analyze 0 errors + 6 pre-existing warnings.

## Docs

Changelog entry; handoff update (reveal live + re-login dogfood step:
consent screen shows the 8 new scopes, then delete a message → tap →
`<mod> deleted <chatter>'s message`); AGENTS.md chat line corrected
(reveal via `channel.moderate` v2, gated on the moderation scope bundle).
