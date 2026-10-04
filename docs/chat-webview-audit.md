# Chat WebView embed notes (Twitch / YouTube / Owncast)

How OBS Blade's **WebView chat path** works and what keeps the embeds alive.
The native engines (Twitch / YouTube / Kick) shipped — see `AGENTS.md` +
`chat-native-roadmap.md` / `youtube-native-chat-audit.md` /
`kick-chat-audit.md`; the WebView remains the free zero-setup viewer and the
per-platform fallback. Owncast is WebView-only.

Code: [`lib/views/dashboard/widgets/obs_widgets/stream_chat/`](../lib/views/dashboard/widgets/obs_widgets/stream_chat/).

## Embed URLs

| Platform | URL loaded | Official? |
|---|---|---|
| Twitch | `https://www.twitch.tv/popout/{username}/chat?darkpopout` | Unofficial embed (Twitch may change DOM / login / cookies) |
| YouTube | `https://www.youtube.com/live_chat?is_popout=1&v={id}&embed_domain=localhost` | Unofficial embed of live chat UI |
| Owncast | `{server}/embed/chat/readwrite` | **Official** Owncast embed |

2026-09-22 hardening pass (live-probed from an EU IP, mobile-Safari UA — all
variants serve the chat bootstrap HTTP 200 today):

- **YouTube URL uses the popout form** (`is_popout=1` + `embed_domain`).
  The bare `live_chat?v=` worked top-level by luck; Google's docs say chat
  embedding is desktop-web-only and requires a matching `embed_domain`. Loaded
  top-level in a WebView there is no parent frame, so the value is
  unverifiable — `localhost` is the conventional placeholder. If YouTube ever
  enforces the check on top-level loads, this form survives.
- **Twitch carries `?darkpopout`** — Twitch's own dark-theme variant; the bare
  popout rendered light inside the dark app.
- **Per-video entries stay** (new stream = new video id = re-edit). The
  alternative — storing a channel `@handle` and auto-resolving the current
  live video via `/@handle/live` — was probed and rejected: mobile UAs land
  on the channel page without resolving, and EU IPs bounce through a
  `consent.youtube.com` redirect that breaks the chain without cookie state.
  Reliable handle→live resolution needs the Data API key, i.e. the native
  engine's territory.

## Hardening layers

- Forced **mobile Safari user-agent**
- JS **MutationObserver** to strip `.consent-banner` nodes (cookie/consent UI)
- **Scroll ownership hack**: pointer Y band → `DashboardStore.pointerOnChat` so the
  parent scroll view doesn’t steal gestures from the WebView
- Username / stream URL stored in Hive (`TwitchUsernames`, `YouTubeUsernames`
  map of label→URL/id, `OwncastUsernames` map of label→base URL)
- YouTube is no longer marked beta in the chat picker (the old
  `DontShowYouTubeChatBetaWarning` flag is unused and kept for existing installs)

Sending messages / emotes in WebView mode = whatever the **embedded site**
supports after the user somehow logs in **inside the WebView** (cookies).
There is no composer, OAuth, or structured emote picker on this path.

### Known fragility / remediation

| Issue | Status |
|---|---|
| WebView recreated every Hive rebuild | **Fixed** — controller created once; `loadRequest` only when URL changes |
| YouTube ID via `split(…)[0]` → `https:` on full URLs | **Fixed** — `extractYouTubeVideoId` + save bare id from dialog |
| No login UX / cookie auth in WebView | Open by design — the native engines carry real send |
| Consent DOM scraping | Open — will keep rotting; Owncast exception |
| Heavy WebView on phones | Mitigated by not mounting when no username |

## Related

- Settings keys: `SelectedChatType`, `*Usernames`, YouTube beta warning
- Helpers: `lib/utils/youtube_video_id.dart`, `test/chat/youtube_video_id_test.dart`
- Odd path: `chat_username_bar.dart/` is a **directory** named `*.dart`
- OBS WebSocket docs intentionally exclude chat
