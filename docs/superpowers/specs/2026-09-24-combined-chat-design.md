# Combined chat (Twitch + YouTube + Kick) — design

**Date:** 2026-09-24 · **Status:** design, awaiting user review · **Process
tier:** L (multi-day, touches all three chat stores + persistence) — full
SDD per `docs/superpowers/plan-defect-checklist.md` §0 once the plan exists.

## Intent

One native timeline that interleaves the chats of up to three platforms.
Three audiences, one flow:

- **Streamers** — "My chats": their own Twitch / YouTube / Kick channels
  folded together (the "You" entries shipped in `dd4f4f1a`).
- **Mods** — their streamer's channels on each platform, with mod actions
  routed to the platform a message came from.
- **Viewers** — anyone's channels, read-only is fine.

## Ratified decisions (brainstorm 2026-09-24)

| Question | Decision |
|---|---|
| Placement | **`Combined` chat-type entry** next to Twitch / YouTube / Owncast / Kick. Native-only (no WebView engine), Pro-gated like the other native engines. The username-dropdown slot lists saved combos. |
| Combo scope | **One channel per platform**, max 3 sources. |
| Same-streamer verification | **None enforced** — the user decides; mixing streamers (co-streams, raids, a mod covering two channels) is legitimate. Rows always carry their source so a mix is visible. |
| Matching help | **Suggest, user confirms** — after one source is picked, look up the same name on the other platforms (Kick slug resolve and a YouTube `@handle` page check, both quota-free; Twitch search when signed in) and offer tappable suggestions. Never auto-added. |
| "My chats" | **Built-in combo**, always first, derived from the signed-in "You" entries; a platform appears once you sign in there, each can be toggled off. Not editable beyond the toggles, not deletable. |
| Row source | **Platform icon** before the name, in the brand color. A channel chip is added only when the combo's sources belong to different streamers (see "Mixed combos"). |
| Writing | **Target picker** in the input: a platform chip that defaults to the last-used target (first: own platform). A reply always goes to the replied message's platform. Only writable platforms can be picked. |
| Events | Subs / gifts / raids, announcements + pins, mod lifecycle (tombstones, ban purges, `/clear` banners — scoped to their source), history backfill — **all in scope**, each honoring its platform's existing notice toggles. |
| Pins | **Stacked, one banner per source**, each with its platform icon and its **own** tuck/restore pin button. |
| Dead sources | **Status strip**: the timeline runs with whatever connects; a slim strip above it shows one status dot per source. Tapping a dot fixes it (sign in, set up the API key, retry). |
| Store coupling | **Shared** — a combo drives each platform store's selection (one live connection per platform, no duplicates). |
| Leaving Combined | **Restore + focus shortcut.** Switching the chat type back to a platform restores what that platform showed before the combo. Separately, tapping a source icon in the status strip "focuses" that platform on the combo's channel, with a **"↩ Combined" chip** to come back. |
| Background while in a single-platform view | **Twitch + Kick keep running** (connections are free), **YouTube pauses** (quota) and catches up on its next poll when you come back. |

## ⚠ Conflict to resolve at review: "shared" vs. "restore" + "keep running"

With **shared** coupling, a platform store can only show one channel. Once
the user switches from Combined to plain Twitch and that view **restores**
the previous channel (not the combo's), the Twitch store is now on the
previous channel, so it **can't** also keep the combo's Twitch source
running in the background. Two of the ratified answers can't both hold as
stated.

**Proposal (default unless you say otherwise):**

- **Focus shortcut** (tap a source icon): the platform view shows the
  **combo's** channel. Background sources keep running (Twitch/Kick) or
  pause (YouTube), as ratified. "↩ Combined" returns with no reconnect and
  no gap.
- **Explicit type switch** (chat-type dropdown → Twitch): restores the
  previous channel. That platform's combo source is **dropped** while
  you're away (its store now serves the restored channel); the **other**
  sources follow the background rule. Returning to Combined re-selects the
  combo's channel on that store. Twitch/Kick backfill history, and the
  per-channel buffers restore what was seen before, so the gap is at most
  the time spent away.

The alternative (store-per-channel instances, so both can live at once) is
the "independent" option already turned down: a large refactor for all
three stores.

## Architecture

### Data model

- `ChatType.Combined` — new enum value, **`@HiveField(4)`**. The existing
  adapter's `default:` branch reads unknown bytes as `Twitch`, so a
  **downgrade** reads a persisted Combined selection as Twitch; that's
  acceptable and should be noted in the release notes.
  Every exhaustive `switch (chatType)` (≈12 sites) and the 14 Owncast-style
  per-type branches need a Combined arm: WebView URL (none), username
  dropdown (combos), brand color (neutral / multi-color icon),
  `nativeChatAvailableFor` (true), engine switch (hidden — Combined is
  native-only).
- **Combos** persist as settings JSON (no new Hive type, same approach as
  `NativeChatChannels`): `SettingsKeys.CombinedChats` =
  `List<{id, name?, twitch?: {id, login, displayName}, youtube?:
  {target}, kick?: {slug}}>` and `SettingsKeys.SelectedCombinedChat` (combo
  id; the reserved id `my` = the built-in "My chats"). "My chats" is
  never persisted as an entry, only its per-platform toggles
  (`SettingsKeys.MyChatsDisabledPlatforms`).
- Source references reuse each store's own identity: Twitch channel ref
  (id/login), YouTube target (`channel/UC…`, `@handle`, or a video id),
  Kick slug. The own entries resolve through the `isOwnChannel` contract.

### `CombinedChatStore` (new, GetIt singleton)

Owns: the combo list + selection, the per-source status, the merged
timeline and the saved pre-combo selections for "restore".

- **Activation** (select a combo while type = Combined): for each source,
  remember the store's current selection (`_restoreSelections`) and call
  `selectChannel(source)` on it. Deactivation (explicit type switch)
  restores them, following the rule above.
- **Merged timeline**: a computed, ordered view over the three stores'
  visible message lists, wrapped in a `CombinedItem` sealed type
  (`{platform, sortKey, payload}`). Sort key = the platform's timestamp
  (Twitch `receivedAt`, YouTube `publishedAt`, Kick `createdAt`),
  falling back to arrival order; ties keep arrival order. The stores keep
  their 500-row caps; the merged view shows the last N (≈500) overall.
- **Status per source**: derived from each store's connection state (and
  YouTube `awaitingLiveStream` / `chatQuotaExhausted`, Twitch login,
  YouTube configured) → `live / connecting / offline / needsSetup /
  error`, feeding the status strip.
- **Background rule**: on a focus or type switch away from Combined, pause
  the YouTube poll (the store's existing flow bump), leave Twitch/Kick
  running. Coming back resumes YouTube from its buffered page token.
- **Suggestions**: `suggestMatches(platform, name)` → a quota-free lookup
  per other platform, results only (the builder UI decides).

### Rendering

- `NativeCombinedChatView`: one list; each item renders with its
  platform's **existing row widget** (`TwitchChatMessageRow`,
  `YouTubeChatMessageRow`, `KickChatMessageRow`, the notice rows), plus a
  leading platform icon slot (new optional `leading` on the rows, or a
  thin wrapper). Filters, highlights, zebra, timestamps and the history
  divider come from the shared `NativeChatAppearance` /
  `ChatFilterSettings`. One "New messages" divider after the merged
  history.
- Tombstones / purges / clear banners come from each store as-is (they
  already mutate their own lists); the merged view only reflects them.
- **Pins**: up to three `PinnedChatBanner`s stacked, each with the
  platform icon and its own tuck state (the per-banner tuck state moves
  from the view into a keyed map).
- **Long-press**: opens the platform's existing sheet (Twitch mod sheet,
  YouTube / Kick action sheets) for that message's store.
- **User card**: the platform's card.
- **Input**: `NativeChatInput` + a target chip; send goes to the chosen
  platform's store (`sendChatMessage` / Twitch send / Kick send). A reply
  locks the chip to the message's platform. The emote picker and
  autocomplete follow the chosen target.

### Chat bar

- Type dropdown: `Combined` entry (a small three-dot multi-brand icon).
- Combo dropdown: "My chats" (You), saved combos, then "New combined
  chat…" and long-press → edit / delete (the Kick / YouTube dropdown
  idioms).
- The right cluster: options (shared appearance + per-source notice
  toggles), no single account chip — the status strip dots are the
  account/setup entry points.

### Builder sheet (`CombinedChatBuilderSheet`, on `NativeChatSheetScaffold`)

One row per platform: `[icon] [channel picker ▾] [status]`. The picker
lists the platform's own entry (You), added channels and "Other…" (typed
name / search). After the first pick, empty rows show suggestion chips
("Found `xqc` on Kick"). Optional name field; the default name joins the
sources' display names. Validation: ≥ 2 sources.

### Streaming mode

`StreamChat(hideUsernameBar: true)` renders the combined view the same
way; the status strip folds into the floating header overlay.

## Waves (proposal)

1. **Read-only merge + My chats.** `ChatType.Combined` + persistence,
   `CombinedChatStore` (activation / restore, merged timeline, status
   strip), platform icon rows, stacked pins, history divider,
   events/lifecycle pass-through. No builder, no writing.
2. **Builder + saved combos + suggestions + focus shortcut** (↩ Combined
   chip, background rule).
3. **Writing + mod in Combined**: target picker, replies, per-platform
   long-press sheets, emote picker / autocomplete following the target.

Each wave ends with the full chat gate and a dogfood install.

## Risks / open items

- **Persistence**: a new `ChatType` ordinal on a 500k-user app — covered
  by an adapter round-trip test and a downgrade note. Combos are plain
  settings JSON (no new typeId).
- **Timestamp skew** across platforms (YouTube polls every few seconds, so
  its rows arrive in bursts): sorting by the platform timestamp keeps the
  order right, but rows may insert **above** the bottom. That needs the
  pinned-to-bottom logic to key on the newest item rather than on the
  count only. Test this explicitly.
- **YouTube quota**: Combined doesn't add polls (one channel), but "My
  chats" enables YouTube polling for streamers who never opened YouTube
  chat, so the status strip should make the quota state visible.
- **Kick Pusher → Centrifugo** migration risk (existing watch item)
  applies unchanged.
- **Twitch reading needs a login** (EventSub) — a viewer without a Twitch
  account gets the "sign in" dot for that source; the rest still works.
