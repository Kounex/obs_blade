# Native Twitch chat — emote picker (first-party + 7TV/BTTV) (design)

Date: 2026-08-06 · Status: approved in brainstorming, pending implementation plan

## Context

The native Twitch chat on `master` reads and writes (send dock with
`user:write:chat`, role badges, inline first-party and third-party 7TV/BTTV
emote rendering). What it lacks is a way to *compose* emotes: the user must
type emote codes from memory. Twitch's own composer (and the WebView embed,
when logged in) offers an emote picker — this is the first feature where the
native engine is strictly behind the WebView it replaces.

The 7TV/BTTV catalogs already sit session-scoped in `ThirdPartyEmoteStore`
(fetched on chat connect, toggle-gated). First-party emotes need one new
read-only Helix call (*Get User Emotes*) behind a new scope
(`user:read:emotes`). Everything else follows the badge/emote wave
architecture end-to-end.

## Decisions (from brainstorming, user-approved)

1. **Bottom sheet, not an anchored popover.** `ModalHandler.showBaseBottomSheet`
   is the app's only sheet idiom — keyboard-aware (rides above the open
   keyboard via `viewInsets` padding), 640pt-capped, rounded top. No
   popover/overlay machinery exists in the app; introducing it for one
   feature is unjustified.
2. **Picker button always visible when logged in; pre-upgrade sessions get a
   re-login CTA inside the sheet** — mirrors the read-only lock-strip
   philosophy (`user:write:chat` upgrade precedent). Hiding the button would
   make the feature undiscoverable for the entire existing user base (they
   hold read+write tokens without `user:read:emotes`).
3. **One combined third-party section ("Third-party (7TV/BTTV)")** in the
   picker, read from the existing `ThirdPartyEmoteStore`, shown only when
   the third-party toggle is on. The store's merged map deliberately drops
   provider attribution (merge precedence already applied), so a single
   alpha-sorted section is the honest presentation — not separate 7TV/BTTV
   sections. Tapping inserts the code; the echo renders it inline via the
   existing row tokenization.
4. **Search field included** (client-side filter over already-loaded
   catalogs). A broadcaster can have hundreds of usable emotes; a grid
   without filter is dead on arrival.
5. **Get User Emotes with `broadcaster_id` = own channel** — returns exactly
   the emotes usable in the user's own chat (globals + own channel
   sub/follower/bits emotes), which is precisely what the picker should
   offer. No other-channel emotes.

## Verified API facts

**Helix Get User Emotes** (Twitch API reference,
dev.twitch.tv/docs/api/reference/#get-user-emotes):

- `GET https://api.twitch.tv/helix/chat/emotes/user` — user access token
  with scope **`user:read:emotes`**; `user_id` must match the token's user.
- Query params: `user_id` (required), `broadcaster_id` (optional filter),
  `after` (pagination cursor).
- Response: `{ "data": [ { "id", "name", "tier", "emote_type",
  "emote_set_id", "owner_id", "format", "scale_available", "theme_mode" } ],
  "pagination": { "cursor"? } }`. `emote_type` documented values:
  `bitstier` | `follower` | `subscriptions`. Empty `pagination` ⇒ last page.
- We read **id, name, owner_id** (and keep `emote_type`/`emote_set_id` raw
  for future use) and drop the rest. Image URLs come from the existing
  `twitchEmoteUrl(id)` CDN helper (`/emoticons/v2/{id}/default/dark/2.0`),
  which serves the animated variant where one exists — no `images` field
  needed.
- **Grouping rule: `owner_id == broadcasterId` → "Channel" section,
  everything else → "Global".** Deliberately not keyed on `emote_type`:
  the enum's behavior for global emotes is the least-documented part of
  this endpoint, and owner comparison is robust to it. *Risk:* if dogfood
  shows global emotes missing from the response entirely, the fallback is
  one extra unscoped call (*Get Global Emotes*) merged into the Global
  section — noted for the plan, not pre-built.
- First **paginated** endpoint in the codebase: accumulate `data` across
  pages via `pagination.cursor` → `after` until no cursor. Bounded loop
  (hard cap, e.g. 50 pages) as a defensive measure against cursor loops.

**Scope upgrade** (`user:read:emotes` appended to `kTwitchChatScopes`):

- Compile-time constant → every new login requests it automatically;
  persisted pre-upgrade tokens simply lack it (`TwitchAuth.scopes`,
  `@HiveField(3)`).
- Capability check mirrors `canWriteChat`: deliberately non-reactive plain
  getter on `_TwitchChatStore` reading the persisted scopes (scopes change
  only at login/logout, which flips `[user]`/`[authState]` and rebuilds
  observers anyway).

## Architecture

### 1. `TwitchUserEmote` — DTO

`lib/types/classes/twitch/twitch_user_emote.dart`. Freezed,
`@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)`
(same idiom as the badge DTOs): `id`, `name`, `ownerId`, `emoteType`,
`emoteSetId` — the latter two as **raw strings** (no enum; unknown values
must not crash parsing).

### 2. `TwitchEmoteService` — API call

`lib/utils/twitch/twitch_emote_service.dart`, injectable `http.Client`
(same test seam as `TwitchBadgeService`). One method:

```dart
Future<List<TwitchUserEmote>> fetchUserEmotes(String accessToken, {
  required String userId,
  required String broadcasterId,
})
```

`TwitchAuthService.helixHeaders(accessToken)`; non-200 →
`TwitchAuthException(message, cause: body, statusCode: code)` (same policy
as badges: store-side 401/403 = dead credentials, 5xx = transient).
Accumulates pages via `after`.

### 3. `TwitchEmoteStore` — session catalog

`lib/stores/views/twitch_emotes.dart` (MobX, GetIt lazy singleton beside
`TwitchBadgeStore`/`ThirdPartyEmoteStore` in `main.dart`). Session-scoped,
in-memory only:

- `ObservableList<TwitchUserEmote> channelEmotes` / `globalEmotes`
  (split at fetch time by the owner rule, alpha-sorted by `name`).
- `@observable int catalogVersion` — pop-in rebuild signal, same role as
  the third-party store's (picker grid rebuilds once when the catalog
  lands).
- `Future<void> fetch(...)` with the generation guard + `_tryFetch`
  degrade-to-none policy (catalog is nice-to-have; a failed fetch never
  surfaces as a chat error).
- `void clear()` on logout.
- Constructor injection `{TwitchEmoteService? service}`.

### 4. Wiring — `TwitchChatStore` + scope

- `kTwitchChatScopes` += `'user:read:emotes'`; new `bool get canReadEmotes`
  on `_TwitchChatStore` (pattern: `canWriteChat`).
- `TwitchChatStore({..., TwitchEmoteStore Function()? firstPartyEmoteStoreResolver})`
  — same resolver seam as badges/third-party.
- `connectChat()`: after the third-party block, fire-and-forget
  `fetch(userId/broadcasterId = this.user!.id)` **gated on `canReadEmotes`**
  (pre-upgrade sessions: no call at all), whole block guarded in try/catch
  (nice-to-have policy — a missing box/lookup must never break connect).
- `logout()`: guarded `clear()` beside the badge/emote clears.

### 5. Dock seam — `NativeChatInput` stays generic

Two optional params, both Twitch-free (the widget's stated contract):

- `TextEditingController? controller` — when provided, the dock uses it
  instead of its private one (ownership transfers to the caller; the dock
  must not dispose an external controller).
- `FocusNode? focusNode` — same external-ownership pattern; lets the
  caller refocus the field after the picker sheet closes.
- `Widget? leading` — rendered in the dock Row before the `Expanded`
  TextField (with `SizedBox(width: AppSpacing.sm)` separation, matching
  the send-button spacing).

### 6. Picker UI (Twitch-aware layer)

New `chat_emote_picker.dart` next to `native_chat_options_sheet.dart`,
composed in `stream_chat.dart`'s native branch:

- `stream_chat.dart` creates one `TextEditingController` for the dock and
  passes it down; the picker button goes into `leading`
  (`ChatEmotePickerButton`, 44pt container style mirroring
  `NativeChatOptionsButton`, emote/smiley icon, `Pressable(haptic: true)`,
  Tooltip). Rendered only when `loggedIn` (the dock itself already only
  renders then).
- `ChatEmotePickerSheet` via `ModalHandler.showBaseBottomSheet` (the dock's
  field is unfocused on open so the sheet never fights an open keyboard
  for vertical space; refocused only after an insert):
  - **Search field** on top (autofocus off — the dock's keyboard context
    transfers to the sheet); filters all sections client-side,
    case-insensitive `contains` on the emote code.
  - **Grid sections** in order: Channel → Global → Third-party (7TV/BTTV)
    (a section renders only when non-empty after filtering; the
    third-party section only when the third-party toggle is on and
    catalogs loaded). Section headers styled like the options sheet's
    section labels.
  - First `GridView` in the app: `SliverGridDelegateWithMaxCrossAxisExtent`
    (~56pt cells so columns adapt phone↔tablet), 44pt+ tap targets
    (`kMinInteractiveDimensionCupertino` precedent), `Image.network` 2x
    with `errorBuilder` → emote code text (same fallback policy as rows).
  - **Tap** → insert `code + ' '` at the controller's cursor (`selection`
    aware; append at end when no selection), close the sheet, refocus the
    dock's field (FocusNode threaded from `stream_chat.dart`).
  - **Pre-upgrade state** (`!canReadEmotes`): no grid — lock icon +
    "Re-login to load emotes" CTA → `startTwitchLogin(context)` (same
    entry point as the lock strip). Third-party sections *do* still show
    in this state (they need no scope) — the CTA sits above them.
  - **Loading/empty**: fetch in flight → spinner in the first-party
    sections area; failed fetch → first-party sections simply absent
    (degrade), third-party unaffected; everything empty + no third-party →
    "No emotes available" placeholder.

### 7. Stores pop-in

The sheet body wraps an `Observer` reading
`TwitchEmoteStore.catalogVersion` + `ThirdPartyEmoteStore.catalogVersion`
so catalogs landing while the sheet is open pop in once (not per row).

## Error handling & edge cases

- **Pre-upgrade token** (`!canReadEmotes`) → no fetch, sheet shows the
  re-login CTA. Cancelled re-login restores `loggedIn` (already handled by
  the `user:write:chat` upgrade path).
- **401/403 from Helix** → store treats as dead credentials (existing
  policy in `_tryFetch`-adjacent code: wipe session → login screen).
  5xx/network → degrade to no first-party emotes this session.
- **Pagination**: loop until empty `pagination.cursor`, hard cap 50 pages
  (defensive; realistic catalogs are 1–3 pages).
- **Unknown `emote_type` values** → harmless (raw string, grouping uses
  `owner_id`).
- **Empty catalog** (new channel, no globals) → sections absent; sheet
  shows placeholder or third-party only.
- **Toggle interplay**: third-party sections follow the existing
  `TwitchChatThirdPartyEmotes` setting (default-on); the picker itself has
  no separate toggle (first-party emotes are core Twitch).
- **Insertion**: respects the dock's existing 500-char cap path — the
  counter reads the same controller, so inserted codes count like typed
  text. No paste-special-casing.
- **Send while sheet open**: sheet is modal; dock is inert underneath —
  no interleaving.
- **Account switch / logout**: `clear()` + generation guard (a late fetch
  from the old session cannot populate the new one's catalog).

## Testing

Mirrors the badge/emote waves (`test/chat/`, fakes extend real services,
`HiveTestHarness`, MockClient-only HTTP):

- **Service**: single-page parse; multi-page accumulation (`after` cursor
  asserted); malformed entries skipped; non-200 → `TwitchAuthException`
  with status.
- **Store**: owner-rule grouping + alpha sort; generation guard (parked
  gate completer, superseded fetch cannot overwrite); clear bumps version.
- **Wiring** (`twitch_chat_store_test.dart` group): connect fetches when
  `canReadEmotes`; skipped when the persisted scopes lack it; logout
  clears. Scope-string assertion in `twitch_auth_service_test.dart`
  updated for the third scope.
- **Dock** (`native_chat_input_test.dart`): external controller insertion
  (cursor mid-text, no-selection append); leading slot renders;
  external controller NOT disposed by the dock.
- **Picker sheet** (widget tests): sections render in order with headers;
  search filters across sections; tap inserts `code + ' '` into the passed
  controller; re-login CTA state when `!canReadEmotes`; third-party
  sections hidden when the toggle is off; pop-in on `catalogVersion`.
- **Gates**: `test/chat/ test/websocket/ test/persistence/` green;
  analyze 0 errors (6 pre-existing warnings tolerated, no new ones).

## Out of scope

- Autocomplete-as-you-type in the dock (future send polish, alongside
  replies/announce).
- Recently-used / frequently-used emote row (needs usage persistence —
  deliberate cut; revisit after dogfood).
- FFZ emotes (consistent with the third-party wave's provider cut).
- Emote pickers for channels other than the user's own (the chat engine
  only connects to the own channel).
- Zero-width 7TV emote compositing (documented limitation of the render
  wave; picker inserts them as normal codes).
- Emoji keyboard (OS keyboards cover this).
