# Native Twitch chat — third-party emotes (7TV/BTTV) (design)

Date: 2026-08-06 · Status: approved in brainstorming, pending implementation plan

## Context

The native Twitch chat on `master` reads and writes (engine switch, container
UI, role badges + toggles, send input). Third-party emotes (7TV/BTTV/FFZ)
arrive as plain **text** fragments — EventSub's `channel.chat.message` payload
knows nothing about them — so tokens like `peepoHappy` render as literal text
today (graceful fallback; dogfood note (c) in the handoff). This feature
renders them inline, mirroring the badge wave's architecture end-to-end.

First-party Twitch emotes are unaffected: they arrive as `emote` fragments
with a Twitch emote id and render via `twitchEmoteUrl()` exactly as today.

## Decisions (from brainstorming)

1. **Providers: 7TV + BTTV.** Both are small public REST APIs with no auth.
   FFZ is out — a third payload shape for comparatively little current usage.
2. **Master toggle, default-on**, in the native chat options sheet (Twitch
   section) — same posture as the badge-visibility toggles and every
   standalone chat client.
3. **Render-time lookup** in `TwitchChatMessageRow` (mirrors badges). Not
   ingest-time resolution in `TwitchChatStore` (messages arriving during the
   fetch window would stay emote-less; toggles wouldn't retro-render), and not
   a static pass-down map (no pop-in, diverges from the established pattern).
4. **Precedence: channel > global; 7TV > BTTV** on same-scope name ties.
5. **No new dependencies** — `http` for the API, `Image.network` for images
   (Flutter's memory image cache). No `cached_network_image`, no disk cache.

## Verified API facts

Checked live on 2026-08-06 (all endpoints public, unauthenticated):

**7TV v3**

- Channel: `GET https://7tv.io/v3/users/twitch/{broadcasterId}` →
  `{ "emote_set": { "emotes": [ { "id", "name", "data": { "host": { "url",
  "files" }, "animated" } } ] } }`. Channels that never used 7TV return
  **404** (verified). A channel may also have no active `emote_set` or an
  empty `emotes` array.
- Global: `GET https://7tv.io/v3/emote-sets/global` → `{ "emotes": [...] }`
  (same emote shape).
- `data.host.url` is **protocol-relative** (`//cdn.7tv.app/emote/{id}`);
  `files` include `2x.webp` (64px) with `static_name` variants. Image URL:
  `https:{host.url}/2x.webp`. Animated emotes are animated WebP, which
  Flutter's `Image.network` decodes; AVIF variants exist but are skipped
  (no Flutter AVIF decoder).

**BTTV v3**

- Channel + shared: `GET https://api.betterttv.net/3/cached/users/twitch/{broadcasterId}`
  → `{ "channelEmotes": [...], "sharedEmotes": [...] }` with entries
  `{ "id", "code", "imageType", "animated" }`. Unknown channels return
  **404** (verified); known channels may return empty arrays (verified).
- Global: `GET https://api.betterttv.net/3/cached/emotes/global` → flat
  array `[ { "id", "code" } ]`.
- Image URL: `https://cdn.betterttv.net/emote/{id}/2x` (CDN serves the
  animated variant when the emote is animated).

**Matching rule** (both providers): exact, case-sensitive,
whitespace-delimited tokens only — `peepoHappy!` glued to punctuation stays
text (same rule other chat clients apply). In practice tokens are split on
the single space character; EventSub chat text is single-line, so other
whitespace effectively doesn't occur (and simply wouldn't match if it did).

## Architecture

### 1. `ThirdPartyEmote` — shared shape

`lib/types/classes/twitch/third_party_emote.dart`. Plain immutable class
(`name`, `imageUrl`) — **no freezed**: two fields, and the provider payloads
are too irregular to model fully (we read name + image host and drop the
rest). Lives next to the other Twitch DTOs since it's Twitch-chat-scoped.

### 2. `ThirdPartyEmoteService` — API calls

`lib/utils/twitch/third_party_emote_service.dart`, injectable `http.Client`
(same test seam as `TwitchBadgeService`). Four methods, each returning
`Map<String, ThirdPartyEmote>` keyed by emote name:

- `fetchSevenTvGlobal()` / `fetchSevenTvChannel(broadcasterId)`
- `fetchBttvGlobal()` / `fetchBttvChannel(broadcasterId)` (channel +
  shared emotes merged)

Status-code policy: **404 → empty map** (expected for channels without a
presence — the common case, must not log as an error); any other non-200 →
throw, caller degrades. Malformed entries (missing name/url) are skipped
silently; unknown JSON fields ignored.

### 3. `ThirdPartyEmoteStore` — catalog cache

`lib/stores/views/third_party_emotes.dart`, MobX, registered as a GetIt lazy
singleton in `main.dart` next to `TwitchBadgeStore`. Session-scoped,
in-memory only — catalog failures degrade to "no third-party emotes", never
to a chat error.

- One merged `ObservableMap<String, ThirdPartyEmote>` (name → emote).
- `@observable int catalogVersion` — bumped once per applied fetch; the
  chat view's outer `Observer` reads it so visible rows rebuild once when
  catalogs land (the accepted badge pop-in behavior).
- `String? emoteImageUrl(String token)` — single lookup used by the row.
- `Future<void> fetch({required String broadcasterId})` — `Future.wait` over
  the four endpoints with per-endpoint try/catch (logged via
  `GeneralHelper.advLog`, null → skipped), generation guard identical to
  `TwitchBadgeStore` (a superseded fetch's late results must not overwrite
  the newer catalog on rapid reconnect / account switch).
- Merge order (later wins): global-BTTV → global-7TV → channel-BTTV →
  channel-7TV. Net precedence: channel > global, 7TV > BTTV on ties.
- `void clear()` — bumps the generation **and** `catalogVersion`, empties
  the map (the version bump lets the view rebuild rows back to plain text).
  Called on logout.

### 4. Trigger wiring — minimal `TwitchChatStore` change

Same two seams the badges use:

- New `_emoteStoreResolver` constructor seam (default
  `() => GetIt.instance<ThirdPartyEmoteStore>()`), injectable for tests.
- Fetch: right beside the badge fetch in `twitch_chat.dart` (~:289),
  fire-and-forget `unawaited(...fetch(broadcasterId: user.id).catchError(log))` —
  but **only when the toggle is on** (read from the Settings box at connect
  time). No auth token needed.
- Clear: beside the badge `clear()` in the logout path (~:253), wrapped in
  the same try/catch-and-log style.

### 5. Rendering — `twitch_chat_message_row.dart`

`_messageSpans()` keeps the current fragment handling; **text** fragments
additionally get tokenized:

- Split `fragment.text` on `' '`; rejoin with single-space `TextSpan`s
  between tokens (spacing preserved exactly, including leading/trailing and
  repeated spaces).
- Per token: if the toggle is on (read from the row's `settingsBox`,
  default-on) **and** `ThirdPartyEmoteStore.emoteImageUrl(token)` hits →
  `WidgetSpan` with `Image.network(url, height/width: _emoteSize=20,
  fit: contain, errorBuilder → Text(token))` — same size and fallback
  policy as first-party emotes. Otherwise `TextSpan(token)`.
- Lookup is exact and case-sensitive; emote fragments (first-party) are
  untouched.

### 6. View rebuild wiring — `native_twitch_chat_view.dart`

- The existing outer `Observer` additionally reads
  `ThirdPartyEmoteStore.catalogVersion` → one rebuild wave of the visible
  list when catalogs arrive (pop-in), and on `clear()`.
- The existing `HiveBuilder.rebuildKeys` gains the emote toggle key →
  toggling re-renders rows in place (same path as badge toggles).

### 7. Toggle — settings key & options sheet

- `SettingsKeys.TwitchChatThirdPartyEmotes` → `'twitch-chat-third-party-emotes'`
  (follows the `'twitch-chat-badge-*'` naming), default-on, Settings box.
- `native_chat_options_sheet.dart` (Twitch section): "Third-party emotes
  (7TV/BTTV)" switch beside the badge toggles.

## Error handling & edge cases

- Channel **404s are expected** (no 7TV/BTTV presence) → empty map, no
  error log. Other non-200s and network failures degrade per endpoint —
  one failing endpoint never blocks the other three.
- No dedicated retry loop: `fetch` runs on chat connect (login / manual
  retry). Internal EventSub reconnects do NOT refetch — a catalog that
  failed at connect stays absent for the session (same posture as
  badges).
- Offline at connect → no third-party emotes this session (text fallback,
  today's behavior).
- Image load failure at render time → `errorBuilder` shows the text token.
- Superseded fetch (rapid reconnect / account switch) → generation guard
  drops late results.
- Toggle off → rows stop resolving (catalog kept in memory for instant
  toggle-on; cleared only on logout).
- **Zero-width** 7TV emotes render as normal inline emotes (no overlay
  compositing) — documented limitation.
- Token followed by punctuation (`PEEPO!`) does not match — exact
  whitespace-delimited tokens only.
- The broadcaster's own messages sent from the native input echo back via
  EventSub as text fragments → the same tokenization renders their 7TV/BTTV
  codes as emotes in-app automatically.

## Testing

Mirror the badge suite under `test/chat/` (fake `http.Client`, no real
network):

- `third_party_emote_service_test.dart` — fixture parsing per provider
  (7TV: `emote_set.emotes` shape, protocol-relative host → `https:` URL,
  entries missing name/host skipped; BTTV: channel+shared merge, global
  array shape); 404 → empty map; other non-200 → throws.
- `third_party_emote_store_test.dart` — merge precedence (channel > global,
  7TV > BTTV tie), per-endpoint degrade (one fails, three apply),
  generation guard (late superseded result dropped), `clear()` resets map +
  bumps version, toggle-off at connect → no fetch issued (via the
  `TwitchChatStore` resolver seam).
- `third_party_emote_row_test.dart` — token → image span, unknown token →
  text, case-sensitivity, punctuation-glued token → text, spacing
  preservation, toggle-off → all text, first-party emote fragments
  untouched.
- Existing gates: `flutter test test/chat/ test/websocket/
  test/persistence/` green + analyze clean.

## Out of scope (explicit)

- FFZ (provider seam is additive if ever wanted).
- Zero-width overlay compositing (renders as a normal emote).
- Emote autocomplete in the send input (future send polish, alongside
  replies/announce; the picker shipped separately on 2026-08-06).
- Disk caching of emote images (memory image cache only).
- Per-provider toggles (single master toggle; YAGNI).
- WebView engines (Twitch's embed renders third-party emotes itself) and
  other platforms' native options.

## Docs hygiene

Public repo: no credentials, tokens, or personal identifiers — the 7TV/BTTV
endpoints are public and unauthenticated. On wrap-up: changelog entry +
handoff reset (dogfood note (c) resolves: third-party emotes now render).
