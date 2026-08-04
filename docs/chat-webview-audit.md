# Stream chat audit (Twitch / YouTube / Owncast)

How OBS Blade shows platform chat today, whether the WebView approach is still
reasonable, and what better paths look like for **read + write + emotes**.

Code: [`lib/views/dashboard/widgets/obs_widgets/stream_chat/`](../lib/views/dashboard/widgets/obs_widgets/stream_chat/).

## What the app does today

Chat is **not** OBS WebSocket. It is a **`webview_flutter` WebView** that loads
each platform’s own chat page / embed:

| Platform | URL loaded | Official? |
|---|---|---|
| Twitch | `https://www.twitch.tv/popout/{username}/chat` | Unofficial embed (Twitch may change DOM / login / cookies) |
| YouTube | `https://www.youtube.com/live_chat?v={id}` | Unofficial embed of live chat UI |
| Owncast | `{server}/embed/chat/readwrite` | **Official** Owncast embed |

Extra “hack” layers:

- Forced **mobile Safari user-agent**
- JS **MutationObserver** to strip `.consent-banner` nodes (cookie/consent UI)
- **Scroll ownership hack**: pointer Y band → `DashboardStore.pointerOnChat` so the
  parent scroll view doesn’t steal gestures from the WebView
- Username / stream URL stored in Hive (`TwitchUsernames`, `YouTubeUsernames`
  map of label→URL/id, `OwncastUsernames` map of label→base URL)
- YouTube still marked **beta** in UI (`DontShowYouTubeChatBetaWarning`)

Sending messages / emotes today = whatever the **embedded site** supports after
the user somehow logs in **inside the WebView** (cookies). There is no native
composer, no OAuth, no structured emote picker.

### Known fragility / remediation

| Issue | Status |
|---|---|
| WebView recreated every Hive rebuild | **Fixed (Phase 0)** — controller created once; `loadRequest` only when URL changes |
| YouTube ID via `split(…)[0]` → `https:` on full URLs | **Fixed (Phase 0)** — `extractYouTubeVideoId` + save bare id from dialog |
| No login UX / cookie auth in WebView | Open — needs native OAuth for real send |
| Consent DOM scraping | Open — will keep rotting; Owncast exception |
| Heavy WebView on phones | Mitigated by not mounting when no username |

## Verdict: is WebView still “best”?

| Goal | WebView today | Native APIs |
|---|---|---|
| “See chat quickly with zero OAuth” | **Still best** | Worse (auth + app review) |
| Owncast read/write | **Official embed is fine** | Optional later |
| Reliable Twitch send / emotes / badges | Poor / fragile | **Clearly better** |
| Reliable YouTube send / Super Chat display | Poor / fragile | Better but heavier (Google OAuth + quotas) |
| Consistent in-app UX (theme, offline, a11y) | Poor | Better |
| Long-term maintenance | High (DOM / ToS / UA) | Higher up-front, lower ongoing for Twitch |

**Overall:** WebView was a smart 2020-era shortcut and is **still acceptable as a
fallback / zero-setup viewer**, especially Owncast. It is **not** the right
foundation if you want a first-class chat experience (compose, emotes, reliable
login). Twitch now has first-party EventSub + Send Chat Message APIs that make a
native client realistic; YouTube has Live Streaming chat APIs but with more
OAuth/quota friction.

## YouTube native visibility check (2026-07-25)

Checked against live Google docs — native YouTube chat **is** publicly available,
same product shape as Twitch (auth → chat id → receive → send), with more cost.

| Piece | Status | Notes |
|---|---|---|
| Receive (poll) | **Visible** | `liveChatMessages.list` |
| Receive (push) | **Visible** | `liveChatMessages.streamList` over **gRPC** (preferred; lower quota) |
| Send | **Visible** | `liveChatMessages.insert` (`textMessageEvent`) |
| OAuth scopes | **Visible** | `youtube` / `youtube.force-ssl` (sensitive → Google verification for production) |
| Chat binding | **Visible** | `liveBroadcast.snippet.liveChatId` — needs an active live video, not channel name alone |
| Quota | **Constraint** | Default **10 000 units/day** per GCP project; naive polling burns it |
| Super Chat / members / polls | **Visible** | Typed message events in the same resource family |
| Custom emoji | **Partial** | Structured in message text; more rendering work than Twitch CDN emotes |
| Flutter fit | **Harder than Twitch** | gRPC streaming vs EventSub WebSocket; Google Sign-In + token refresh |

**Conclusion:** YouTube can be “native like Twitch,” but keep it on **WebView until
Twitch native proves value** (roadmap Phase 4). Phase 0 hardened the embed path
so full URL / bare id storage both work.

## Alternatives (ranked)

### A — Keep WebView, harden only (low ambition) — Phase 0 done

- ~~Fix YouTube video-id parsing~~ → `lib/utils/youtube_video_id.dart`
- ~~Don’t recreate WebView every rebuild~~ → `_syncWebController` in `stream_chat.dart`
- Dialog now validates + persists bare video ids; accepts full links
- Optional later: Custom Tabs login + cookie sync (still fragile)

### B — Hybrid: native Twitch + WebView for YT/Owncast (recommended direction)

1. Twitch Developer application + OAuth (`user:read:chat`, `user:write:chat`).
2. Receive: EventSub `channel.chat.message` over **WebSocket** (device-friendly).
3. Send: Helix `POST /helix/chat/messages`.
4. Emotes/badges: Helix chat emote endpoints + CDN URLs; render in Flutter.
5. Keep YouTube + Owncast on embed until demand justifies native.
6. Optional setting: “Use classic WebView chat” as fallback.

**Pros:** Best ROI — Twitch is likely the primary audience; real composer/emotes;
  no DOM dependency for the important path.  
**Cons:** OAuth UX, App Store privacy strings, Twitch app review of scopes;
  must map username → `broadcaster_id`.  
**Unblocked 2026-08-04:** "OBS Blade Chat" app registered (public client, redirect `http://localhost:14777/twitch-auth-callback`); Client ID in `private/backend-architecture.md`.

### C — Full native all platforms

- Twitch as in B.
- YouTube: see visibility check above.
- Owncast: prefer official embed **or** integration token APIs (bot-style send).

**Recommend:** Only after B proves value.

### D / E — Aggregators / more JS injection

Skip — wrong dependency / ToS treadmill.

## Suggested roadmap

| Phase | Work | Status |
|---|---|---|
| 0 | Fix YT id parse + WebView lifecycle | **Done** (2026-07-25) |
| 1 | Native chat UI shell + Twitch OAuth | **Done** (read-only native chat, DCF + EventSub) |
| 2 | EventSub receive + Helix send + basic emotes | Pending 1 |
| 3 | Polish; keep YT/Owncast WebView | Pending 2 |
| 4 | YouTube native (optional) | Feasible per visibility check |

## Next session

Phase 1 unblocked 2026-08-04 — "OBS Blade Chat" Twitch app registered
(public client, redirect `http://localhost:14777/twitch-auth-callback`;
Client ID recorded in `private/backend-architecture.md`). Resume from
[`session-handoff.md`](session-handoff.md).

Do not stub fake OAuth. Keep YT/Owncast on WebView; no further embed JS
hacks.

## Related

- Settings keys: `SelectedChatType`, `*Usernames`, YouTube beta warning
- Helpers: `lib/utils/youtube_video_id.dart`, `test/chat/youtube_video_id_test.dart`
- Odd path: `chat_username_bar.dart/` is a **directory** named `*.dart`
- OBS WebSocket docs intentionally exclude chat
