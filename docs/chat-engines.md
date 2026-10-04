# Chat engines — shipped state

Moved from `AGENTS.md` (2026-10 docs restructure): the native chat engines
(Twitch, and the shared all-engine mechanics), the combined chat, and the
add-chat sheets. YouTube and Kick engine state live in
[`docs/youtube-native-chat-audit.md`](youtube-native-chat-audit.md) and
[`docs/kick-chat-audit.md`](kick-chat-audit.md); strategy and backlog in
[`docs/chat-native-roadmap.md`](chat-native-roadmap.md) and
[`docs/chatterino-comparison.md`](chatterino-comparison.md).

## Twitch native chat

**Chat:** Twitch has a native engine (device-code login + EventSub chat +
Helix send input — reads AND writes) next to the WebView embeds; a manual
WebView↔Native switch lives in the chat bar (`SelectedChatEngine`, default
WebView; availability seam: `nativeChatAvailableFor` in
`lib/models/enums/chat_engine.dart`). The native side renders in
`NativeChatWindow` (optional `input` slot docks the generic, Twitch-free
`NativeChatInput`; silent `user:write:chat` scope upgrade — pre-upgrade
sessions get a read-only lock strip). **Multi-chat** lets users add other
channels (search / moderated / followed), switch via the chat-bar dropdown
(connect-on-switch, per-channel history), and run delete/timeout/ban in
modded channels (local reconcile + EventSub echo dedup). Room-level mod
actions (`ChannelModSheet` — clear, chat modes, shield, announce) ship via
the chat-bar shield button and native options sheet when moderating. Role badges +
per-category toggles ship via `TwitchBadgeStore` + the native chat options
sheet (per-platform seam); third-party (7TV/BTTV) emotes render inline via
`ThirdPartyEmoteStore` (toggle in the native chat options sheet); an emote
picker (first-party Get User Emotes via `TwitchEmoteStore` + the
third-party catalogs) docks in the native input (`user:read:emotes` silent
upgrade); message lifecycle rides the same session
(`message_delete`/`clear_user_messages`/`clear` → content-visible
tombstones (dimmed content + ` —Deleted` marker) + `/clear` banner,
best-effort subs; a `channel.moderate` v2 sub (gated on the
`kTwitchModerationScopes` 8-scope bundle, pre-upgrade tokens skip it)
supplies the deleting mod for the tap reveal) and scrolled-up chat shows a
pause chip. On join, recent history backfills (dimmed, once per channel per
session) from the community `recent-messages.robotty.de` service
Chatterino uses (`TwitchRecentMessagesService` parses the IRC lines into
`ChatMessageEvent`s; toggle `TwitchChatLoadHistory` → options "Chat
history"; `test/flutter_test_config.dart` mocks its default client
suite-wide). Mod tooling (wave 3): Warn… compose in the mod action sheet,
unban-request Approve/Deny in the ban inbox, and a live AutoMod queue sheet
(`automod.message.hold/.update` v2 → `TwitchChatStore.autoModQueue`) behind
the channel mod sheet — one `kTwitchManageModToolingScopes` scope-upgrade
bundle, pre-upgrade tokens get the re-login CTA on the gated rows. Chat is
also a **dedicated tab** (`Tabs.Chat` — usable without an OBS session; the
dashboard pane is removed) and the **streaming-mode dashboard** embeds chat
as its live co-display surface (floating header overlay via the
`StreamChat.hideUsernameBar` seam). Next:
**wave-4 item selection** — the availability/entitlement gate decision is
resolved (the Pro gate shipped via RevenueCat); what's open is picking the
wave-4 items — see `docs/chat-native-roadmap.md` + the session handoff.

## General native chat (all 3 engines)

Every store answers
`isViewingOwnChannel` (the "You" entry — groundwork for the merged
timeline, see `chatterino-comparison.md`); self-mention/keyword row
highlighting (`ChatHighlightSelfMention` + `ChatHighlightKeywords`, shared
matcher in `chat_highlight_helper.dart`), a client-side mute-word filter,
chat search/filter over each engine's buffered history
(`ChatSearchSheet`), Chatterino-style extras (`docs/chatterino-comparison.md`:
`@user`/emote autocomplete strip, timestamps / zebra rows / readable name
colors, FFZ + zero-width emotes, highlighted/ignored users, `/regex/`
entries, censor mode via `ChatFilterSettings`; backfilled history is
dimmed with a platform-colored "New messages" divider on all engines),
and a "Copy message"
long-press action available even
to fully read-only viewers (`MessageActionSheet`, generalized from
Twitch's non-mod sheet) all ship uniformly. Message rows carry
screen-reader semantics — each row collapses into one
`Semantics(container: true, excludeSemantics: true, label: ...)` node
(raw-field label, not the rendered span tree) with `onTap`/`onLongPress`
as the two exposed actions.

## Combined chat (waves 1-3 shipped)

`ChatType.Combined`
(HiveField 4, native-only — `isNativeOnly`, no engine switch) merges the
signed-in "You" channels ("My chats") into one Pro-gated timeline.
`CombinedChatStore` binds to the persisted chat type app-wide (created
after Hive init in `main.dart`): selecting Combined points each platform
store at its own channel, leaving restores the previous selections
("shared" coupling — no extra connections). `timeline` = stable k-way
merge by platform timestamp (`mergeCombinedStreams`, per-platform order
never changes). `NativeCombinedChatView` reuses each platform's row
widget behind a platform icon; pins stack per platform
(`CombinedPinStack`); sources sheet = status + sign-in/retry + toggles.
Spec: `docs/superpowers/specs/2026-09-24-combined-chat-design.md`; plans:
`docs/archive/plans/2026-09-24-combined-chat-wave1.md` (wave 1),
`docs/archive/plans/2026-09-25-combined-chat-wave2.md` (wave 2).
Wave 2: saved combos of any channels (`CombinedCombo`, settings JSON;
saving registers each source in its platform's own list — the stores
only show what they list), builder sheet with confirm-only same-name
suggestions (`CombinedMatchFinder`: Kick slug, YouTube `@handle` page,
Twitch exact login — quota-free), combo dropdown in the chat bar, a
source strip whose chips jump into one platform
(`CombinedChatStore.focus` → "↩ Combined" strip on that window, no
restore; YouTube `pausePolling` meanwhile). Wave 3 (writing):
`CombinedChatInput` sends to `CombinedChatStore.sendTarget` — a pending
reply's platform, else the target chip's pick (`CombinedChatSendTarget`),
else the first writable source; the emote picker / autocomplete / accent
follow the target. Long-press opens the row platform's own sheet (mod
sheet where allowed, else Copy + Reply); the platform store is already on
the row's channel (shared coupling), so its sheets act on the right
channel as-is. `setReplyTarget` keeps one reply across stores.
Channel mod sheets: Twitch (full Helix), Kick (`KickChannelModPanel`:
modes read-only, session bans + unban, unban by name), YouTube
(`YouTubeChannelModPanel`: polls, session bans, owner-only moderators);
Kick/YouTube shields show whenever signed in (no mod lookup) and 403s
toast `chatNotModeratorText`. Combined: `CombinedChannelModSheet` —
always one tab per source; a tab that can't be moderated
(`combinedModBlock`) explains why + offers the fix. Kick/YouTube have no
ban-list APIs — the `recentBans` lists are what the session saw.
Status language: "LIVE" / the live green = streamer on air only;
connection health is quiet when fine and only surfaces as a problem
marker (`CombinedIssueMarker`) or label.
Channel pickers everywhere: own first then A–Z, menu capped at
`kChatChannelMenuMaxHeight`, `NativeChatLiveTag` (LIVE / OFFLINE /
nothing when unknown) from each store's `liveStateForChannel`; the
combo switcher shows on-air state for every combo
(`CombinedChatStore.liveSourcesOf`). Live data cadence: Twitch Helix
batch 10 s + EventSub `stream.online/offline`; Kick 15 s for the
selected channel (60 s list) + Pusher `channel.{id}` on/off-air events;
YouTube viewers 30 s (quota) — constants `kTwitchLivePollInterval`,
`kKickSelectedLiveInterval` / `kKickListLiveInterval`,
`kViewerRefreshInterval`.

## Add chat sheets (all 3 engines)

The native channel menus and the
combo builder's "Other…" open a searchable picker per platform on shared
chrome (`stream_chat/dialogs/add_chat_sheet_chrome.dart`): Twitch (Helix
search + moderated / followed), YouTube (`search.list`, own 100/day
bucket, + subscriptions when signed in; keyless keeps the dialog), Kick
(the website's anonymous search + the official live listing when signed
in - Kick has no follows API). WebView mode keeps the add dialogs. Facts:
the audits' § Channel discovery.
