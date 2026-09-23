# Chatterino comparison — what to adapt + YouTube channel resolution

Researched **2026-09-24** against shallow clones of
[`Chatterino/chatterino2`](https://github.com/Chatterino/chatterino2) (master)
and [`SevenTV/chatterino7`](https://github.com/SevenTV/chatterino7), plus
wiki.chatterino.com and the multi-platform chat tools that do handle YouTube.
Scope: which Chatterino features are worth porting to our three native
engines (Twitch / YouTube / Kick), and how to stop making YouTube users paste
a new video id for every stream.

Code anchors: `lib/views/dashboard/widgets/obs_widgets/stream_chat/`,
`lib/stores/views/{twitch,youtube,kick}_chat.dart`,
`lib/utils/{twitch,youtube,kick}/`.

## TL;DR

- Chatterino is **Twitch-only** (maintainers declined YouTube in discussions
  #3140/#3298 — "not IRC"; generic IRC was even removed, #5547). Chatterino7
  adds experimental **Kick** (+ a merged Twitch/Kick `MultiChannel` view)
  but still no YouTube. So YouTube is solved from other tools, not Chatterino.
- **YouTube:** resolve **channel → current live video** at connect time and
  re-resolve on stream end (auto-rollover), instead of storing per-stream
  video ids. Build order and design below.
- **Cheap, high-value Chatterino ports** (shipped 2026-09-24): @user/emote
  autocomplete, readability (timeline timestamps, alternating rows, name
  contrast), FFZ + zero-width emotes, highlight/ignore upgrades, Twitch
  recent-messages backfill.
- **Strategic:** a merged multi-platform timeline (Twitch + YouTube + Kick)
  — Chatterino7 only does Twitch+Kick; for OBS multistreamers this is a
  natural Pro headline.

## Our baseline (before this wave)

All three native engines already have: badges, 7TV (+BTTV on Twitch) emotes,
emote picker (Twitch/Kick), mod actions (Twitch: full wave 1–3 surface),
user card, self-mention + keyword highlight, mute words, buffered search,
pins (Twitch/Kick), tombstones, per-platform multi-channel, pause chip. Kick
backfills history on connect; Twitch and YouTube don't. No engine
abstraction — each has its own store + row widget; shared bits are pure
helpers (`chat_highlight_helper.dart`, `chat_mute_helper.dart`,
`chat_search_helper.dart`, `chat_link.dart`) and generic chrome
(`NativeChatWindow`, `NativeChatInput`).

## Chatterino feature inventory → verdict

Paths are chatterino2 unless noted.

| Area | Chatterino | Us | Verdict |
|---|---|---|---|
| Tab completion | `src/controllers/completion/` — `SmartEmoteStrategy`, user + command sources | none (plain field + picker) | **Build now** — suggestion strip over the input, `@user` from buffered chatters, emotes from each engine's catalogs |
| Timestamps | `showTimestamps`, `timestampFormat` | user card only | **Build now** — timeline toggle |
| Alternating rows | `alternateMessageBackground` | hairline separators only | **Build now** |
| Name readability | `colorizeNicknames` (no explicit contrast setting found) | raw Twitch hex | **Build now** — luminance clamp vs. theme background |
| FFZ emotes | `src/providers/ffz/FfzEmotes.cpp` (`api.frankerfacez.com/v1/set/global`, `v1/room/id/<id>`) | none | **Build now** (Twitch) |
| Zero-width emotes | `enableZeroWidthEmotes`; BTTV hardcoded name set, 7TV `flags` bit | rendered as separate inline images | **Build now** — overlay on previous emote |
| Live emote updates | BTTV websocket + 7TV EventAPI | catalogs fetched once | Later (needs sockets) |
| Highlights | `src/controllers/highlights/` — phrase (regex, color, sound), user, badge, blacklist; `/mentions` split; first-message highlight | self-mention + keywords (substring) | **Build now** — highlighted users, first-time chatter highlight, regex opt-in |
| Ignores | `src/controllers/ignores/` — users + phrases, block or replace (`***`) | mute words (drop row) | **Build now** — ignored users + "replace instead of hide" |
| Recent-messages backfill | `src/providers/recentmessages/` → `recent-messages.robotty.de/api/v2/recent-messages/<ch>`, ~800 msgs | none on Twitch | **Build now** |
| Moderation buttons | `src/controllers/moderationactions/` — user-defined buttons, `{user.name}` `{msg.id}` vars | fixed mod sheet | Medium — custom timeout lengths / buttons |
| Custom commands | `CommandController.cpp` — `{1}`, `{1+}`, `{channel.name}`, `{stream.title}` … | none | Medium — could add OBS vars (scene, stream time) |
| Search operators | `src/messages/search/` — `from:`, `has:link`, `is:first-msg`, `badge:`, `regex:` | substring | Medium |
| Streamer mode | `StreamerMode.cpp` — process-list detection (OBS etc.) | none | Medium — we can drive it from OBS `StreamStateChanged` directly |
| Reply threads | `MessageThread.cpp` + thread popup | single-level reply strip | Later |
| Live tab indicator | `NotebookTab::setLive` | none | Medium — dropdown live dots (Helix `streams` batch, Kick channel `livestream`) |
| Mentions view | `Channel::Type::TwitchMentions` | none | Later (cross-channel) |
| User notes | `EditUserNotesDialog.cpp` | none | Later |
| Link previews | `LinkResolver` (Chatterino-hosted resolver) | none | Skip (needs a backend) |
| Splits/tabs, Lua plugins, hotkeys, disk logs, filter language, `/watching` | desktop-shaped | — | **Skip** |

Chatterino7-only (`SevenTV/chatterino7`):

- **7TV paints** (`src/providers/seventv/SeventvPaints.*`, `paints/` — linear/
  radial gradient + URL paints, drop shadows), **personal emotes**
  (`SeventvPersonalEmotes.*`, EventAPI `AnyEmoteSet` subscriptions), animated
  7TV avatars in the user card, 7TV badge animation toggle. Fan-favorite;
  needs the 7TV EventAPI socket → later wave.
- **Kick** (`src/providers/kick/`) with **two transports** — Pusher and
  Centrifugo (`ws/KickCentrifugoManager.cpp`, auth via
  `web.kick.com/api/v1/realtime/auth/connection`) + a
  `kickConnectionPreference` setting. **Watch item for us:** our Kick reads
  ride Pusher only; if Kick migrates, Centrifugo is the fallback.
- **`MultiChannel`** (`src/util/MultiChannel.*`) — one split interleaving
  Twitch + Kick with a per-message platform indicator. Model for our merged
  timeline idea.

## YouTube: channel → live video → chat

### The problem

`SettingsKeys.YouTubeUsernames` stores label → video id/URL; every new
stream is a new video id, so users re-edit the entry each stream. The store
goes `offline` on `liveChatEnded` / `offlineAt` and stays there.

### How other tools solve it

| # | Method | Cost | Scope |
|---|---|---|---|
| a | GET `youtube.com/@handle/live` (or `/channel/UC…/live`), read `<link rel="canonical" href="…watch?v=ID">` | free, no key | any channel, live only |
| a′ | Parse channel `/streams` tab `ytInitialData`, pick `LIVE`/`UPCOMING` | free | any channel, also scheduled |
| b | `search.list?channelId&eventType=live&type=video` | 100 units, separate 100 calls/day bucket | any channel — too scarce to poll |
| c | `liveBroadcasts.list?mine=true&broadcastStatus=active` | OAuth, ~1 unit | own channel only |
| d | RSS `feeds/videos.xml?channel_id=` + `videos.list` | ~1 unit | lags, misses scheduled |

`youtube-chat` (npm) uses **a**; `chat-downloader` (Python) uses **a′** and
re-polls every ~30 s while nothing is live — the cleanest auto-rollover
seen. Streamer.bot uses **c** (own channel only).

Verified here 2026-09-24 (mobile UA, `SOCS`/`CONSENT` cookies to skip the
EU consent interstitial): `@LofiGirl/live`, `@NASA/live` → canonical
`watch?v=…` + `"isLiveNow":true` + `"channelId":"UC…"`; offline `@mkbhd/live`
→ canonical stays `…/@mkbhd/live` (clean "not live" signal).

### Design (shipped in this wave — see changelog)

1. **Entry value = channel or video.** Same `YouTubeUsernames` map, same
   Hive shape (no migration): values may be `@handle`, `UC…` id, a channel
   URL, or a video id/URL as before. A classifier
   (`lib/utils/youtube_target.dart`) returns video vs. channel.
2. **Resolve at connect** (`YouTubeLiveResolver`): pasted video → as today.
   Channel → method **a** (`/live` page scrape, video id only) → existing
   1-unit `videos.list` for `activeLiveChatId`. Chat reads stay on the
   official API; the scrape only finds the id.
3. **Auto-rollover:** a channel entry that's offline or whose chat ended
   re-resolves on a backoff (30 s → 2 min cap) while the store is active,
   and the chat reattaches to the next stream. Video entries keep today's
   terminal `offline`.
4. **WebView** uses the same resolver via `YouTubeWebLiveTracker` (the
   embed needs a `v=`): 45 s rechecks while offline, 2 min while live.

Implementation notes (verified live 2026-09-24 via `dart run` against
@NASA / @LofiGirl / @mkbhd / `c/LofiGirl` / a nonexistent handle): Dart's
`http` client gets the **desktop** variant (~1.2 MB) regardless of the
mobile UA, the canonical tag moves between ~30 KB and ~700 KB deep with
`Accept-Language`, and **offline channel pages emit it after `</head>`** —
so the resolver streams the body with a sliding window (no head cutoff,
3 MB cap) and stops at the tag. Unknown handles 404 (terminal error, no
retries). A live-but-chat-disabled stream costs 1 unit per recheck (≤ 40
units/h at the 90 s tail) — accepted.

Risk: the `/live` scrape is unofficial (layout churn, consent walls). It's
isolated in one function with a manual video-id override always available;
chat traffic itself stays official. Follow-ups: OAuth own-channel path
(**c**) for signed-in streamers, OBS `StreamStateChanged` → immediate
re-resolve.

### Status (2026-09-24, end of session)

Shipped: channel entries + auto-rollover (native + WebView), optional
entry name auto-derived from the channel (display name, no `@`). Open:
OAuth own-channel path (`liveBroadcasts.list`), OBS `StreamStateChanged`
→ immediate re-resolve.

## Build order

Items 1–6 **shipped 2026-09-24** (see `changelog-agent.md`), plus the
platform-colored "New messages" divider after history on every engine.
Next up: the "Medium" rows of the verdict table.

1. YouTube channel resolver + auto-rollover (+ WebView).
2. Twitch recent-messages backfill.
3. Autocomplete (@user + emotes) in `NativeChatInput`.
4. Readability: timestamps, alternating rows, name contrast.
5. FFZ + zero-width emotes.
6. Highlight/ignore upgrades.

Then: medium items (mod buttons, commands, search operators, streamer
mode, live dots), then the strategic merged timeline / 7TV cosmetics.

## Sources

- chatterino2 source (paths above), `CHANGELOG.md`; wiki.chatterino.com
  (Commands, Filters, Search, Moderation)
- chatterino7 source, `CHANGELOG.c7.md` (7.5.5-beta.1 "experimental Kick
  support"), PR #351, issue #352
- Chatterino discussions #3140, #3298 (YouTube), #4676, #4707 (Kick)
- `LinaTsukusu/youtube-chat` `src/parser.ts`; `xenova/chat-downloader`
  YouTube site module; Streamer.bot docs
