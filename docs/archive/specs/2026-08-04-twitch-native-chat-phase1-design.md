# Native Twitch chat — Phase 1 (OAuth + read-only chat)

Status: approved design, 2026-08-04 · supersedes nothing; extends
[`chat-webview-audit.md`](../../chat-webview-audit.md) (Hybrid path B) and
`../../private/backend-architecture.md` (Twitch app registration).

## Context

Chat in OBS Blade today is a `webview_flutter` embed of each platform's own
chat page — fragile for Twitch (DOM/consent scraping, in-WebView login), fine
as a zero-setup viewer. Phase 0 (2026-07-25) hardened the embed path. Phase 1
adds the first **native** chat path: Twitch OAuth + a live, read-only native
chat view rendered inside the existing dashboard chat slot.

Twitch app registration (done 2026-08-04, account-bound): **"OBS Blade Chat"**
— Public client type, category Chat Bot, Client ID
`t3muhu36do5wemeeilzl57v48gwcmh` (public value, hardcoded in source; app was
recreated once, this is the current ID), redirect
`http://localhost:14777/twitch-auth-callback` (console enforces HTTPS except
localhost; unused by the chosen auth flow — placeholder only). Registration
details + rationale: `../../private/backend-architecture.md`.

## Decisions (locked with the user 2026-08-04)

1. **Phase 1 scope = OAuth + read-only native chat.** Sending, badges,
   cheermotes, moderation → Phase 2. YouTube/Owncast stay on WebView.
2. **Coexistence: native + WebView fallback.** Twitch selected + logged in →
   native view. Logged out / YouTube / Owncast → existing WebView path,
   untouched.
3. **Approach A: device code grant (DCF) + EventSub WebSocket reader in the
   existing chat slot.** DCF chosen over implicit+loopback (fragment shim, no
   refresh token, awkward browser handoff) and over a separate preview screen
   (double integration cost).
4. **Single Twitch account**, own channel only, for v1. (A user token with
   `user:read:chat` can technically read arbitrary channels via EventSub —
   out of scope for v1; WebView covers arbitrary-channel viewing.)

Non-goals (explicit): sending messages, emote *picker*, badges, cheermotes,
mentions UI, moderation actions, multiple accounts, arbitrary-channel native
viewing, HTTPS universal-link auth upgrade, YouTube native.

## Architecture

New self-contained feature; **no changes to `DashboardStore`** (the monolith
stays untouched per repo convention). Three layers + one store:

- **Auth service** — `lib/utils/twitch/twitch_auth_service.dart`
  Device code flow, token refresh, validation. Emits auth state.
- **EventSub service** — `lib/utils/twitch/twitch_eventsub_service.dart`
  Dedicated WebSocket to Twitch EventSub + subscription lifecycle.
- **DTOs** — `lib/types/classes/twitch/` (mirrors the OBS `types` layout)
  EventSub message envelope, `channel.chat.message` event, message fragments.
  freezed, same pattern as existing OBS DTOs.
- **Store** — `lib/stores/views/twitch_chat.dart` (`TwitchChatStore`, MobX,
  registered in GetIt): auth state, message buffer, connection status.
- **UI** — `lib/views/dashboard/widgets/obs_widgets/stream_chat/`:
  `native_twitch_chat_view.dart` (message list) + a "Connect Twitch"
  prompt state + device-code dialog. Plugs into the existing slot:
  chat type Twitch **and** logged in → native; otherwise → today's WebView
  (byte-for-byte unchanged).

Client ID `t3muhu36do5wemeeilzl57v48gwcmh` lives in one constants spot in the
auth service. Scopes requested: **`user:read:chat` only** (Phase 2 adds
`user:write:chat` via re-consent).

## Auth flow (device code grant)

1. User taps **Connect Twitch** (shown in the chat widget when Twitch is
   selected and logged out).
2. `POST https://id.twitch.tv/oauth2/device` (client_id, scope) →
   `device_code`, `user_code`, `verification_uri`, poll `interval`, `expires_in`.
3. Dialog shows the short `user_code` + **Open Twitch** button
   (`url_launcher` → `https://www.twitch.tv/activate`), plus polling status.
4. Poll `POST https://id.twitch.tv/oauth2/token`
   (`grant_type=urn:ietf:params:oauth:grant-type:device_code`, device_code,
   client_id — **no secret** for DCF public clients) at the given interval
   until: authorized → token pair (`access_token` + `refresh_token`);
   `authorization_pending` → keep polling; expired/denied → error state with
   retry.
5. On success: persist token pair, then `GET /helix/users` (own id, login,
   display name) → `loggedIn`.
6. **Refresh**: `POST /oauth2/token` (`grant_type=refresh_token`, client_id —
   no secret for DCF-issued tokens) when <5 min remain or on any 401.
   Refresh failure → wipe tokens → clean logged-out state with explanation.
7. **Validate**: `GET https://id.twitch.tv/oauth2/validate` on cold start
   with a stored token (Twitch requires third-party apps to validate
   periodically; 401 → treat as logged out).

Logout: small affordance in the chat bar (not buried in Settings for v1).

## Reader (EventSub WebSocket)

- Connect `wss://eventsub.wss.twitch.tv/ws` (separate socket from OBS;
  `web_socket_channel`, same package the OBS session uses).
- Handle message types: `session_welcome` (extract `session_id`),
  `session_keepalive` (watchdog: timeout → reconnect with backoff),
  `session_reconnect` (follow `reconnect_url`, resubscribe),
  `revocation` (subscription killed → surface state; if auth revoked →
  logged out), `notification` (parse event).
- After welcome: `POST https://api.twitch.tv/helix/eventsub/subscriptions`
  (Bearer user token + Client-Id) with type `channel.chat.message` v1,
  condition `{broadcaster_user_id: <own id>, user_id: <own id>}`,
  transport `{method: "websocket", session_id}`.
- Lifecycle: socket exists only while the native chat view is mounted;
  dispose closes socket + deletes the subscription. Reconnect with backoff
  (patterns from `network_helper.dart`, but **not** shared code — separate
  service).

## Rendering

- Bounded buffer: **500 messages**, oldest trimmed (MobX `ObservableList`).
- Message row: author name in the event's `color` (fallback: theme default),
  text rendered from `message.fragments[]`:
  - `type: text` → inline text
  - `type: emote` → inline image from Twitch CDN
    (`https://static-cdn.jtvnw.net/emoticons/v2/{emote.id}/default/dark/2.0`),
    no extra API calls needed
  - anything else (cheermote/mention) → plain text fallback
- Auto-scroll pinned to bottom; unpin when the user scrolls up, small
  "new messages" affordance to jump back down.
- States for the slot: logged-out prompt, connecting, live, error.
  Reuses the On Air design-system tokens (`AppSpacing`, `AppRadius`, cards).

## Persistence

- New Hive model `TwitchAuth` (`lib/models/twitch_auth.dart`): access token,
  refresh token, expiry, scopes, user id, login, display name. **New typeId
  from the registry** (`lib/models/`) per `persistence-risk.md` discipline —
  never reuse/renumber. Registered in the generated Hive registrar.
- Tokens at rest follow the existing OBS-connection-password practice
  (Hive plaintext) — consistent with today's threat model; flagged here so
  it's a conscious, documented choice.
- Settings key for "last selected chat type" etc. stays as-is.

## Error handling

| Case | Behavior |
|---|---|
| Device code expired | Dialog error + "start over" retry |
| User denies at Twitch | Dialog error + dismiss |
| Poll/network failure | Retry with backoff inside dialog |
| Token refresh fails / validate 401 | Wipe `TwitchAuth`, logged-out state in slot (WebView fallback offered) |
| EventSub keepalive timeout | Reconnect w/ backoff; resubscribe on welcome |
| `session_reconnect` | Follow `reconnect_url`, resubscribe |
| `revocation` (auth pulled) | Logged-out state + explanation |
| Buffer overflow | Trim oldest (no unbounded growth) |

## Testing

- `test/chat/` (existing suite location):
  - DTO parsing from **captured real payloads** (fixtures: regular message,
    emote fragments, cheermote-as-text fallback, keepalive/reconnect/
    revocation envelopes)
  - emote-fragment → inline-span splitting
  - token refresh/validate logic (mock HTTP: success, 401, network error)
  - buffer trim at 500
  - auth state machine transitions (pending → authorized/expired/denied)
- No new package dependencies intended (`http`, `web_socket_channel`,
  `url_launcher` already in `pubspec.yaml` — confirm at plan time).
- Manual dogfood (workstation): real Twitch account, simulator + device;
  confirm messages flow, emotes render, reconnect survives network drop;
  tablet layout smoke (Force Tablet Mode).

## Open verification points (checked during implementation)

- Recreated Twitch app has the localhost redirect + Public type + Chat Bot
  category set as before (user redid registration; first DCF call proves it).
- EventSub WS keepalive/reconnect behavior on iOS when the app backgrounds
  (socket lifetime vs. widget lifecycle may need adjustment).
- Emote CDN URL shape (`/default/dark/2.0`) against real payloads.

## Upgrade path (documented, not built)

- **HTTPS universal-link/app-link auth** (in-app auth sheet, no code typing):
  register a second redirect URL (max 10) on a Kounex domain + host
  `apple-app-site-association`/`assetlinks.json`. Pure addition, no rework.
- **Phase 2**: `user:write:chat` re-consent, Helix `Send Chat Message`,
  badges (Helix badge sets), cheermotes, composer UI.
- **Phase 4 (optional)**: YouTube native (feasibility already verified in the
  chat audit).
