# Combined chat — Wave 2 (saved combos, other streamers, focus shortcut) plan

> Spec: [`../specs/2026-09-24-combined-chat-design.md`](../specs/2026-09-24-combined-chat-design.md).
> Wave 1: [`2026-09-24-combined-chat-wave1.md`](2026-09-24-combined-chat-wave1.md).
> Tier L, executed in-session (commit per task, end self-review + full gate;
> the reviewer subagent is rate-limited on the secondary model).

## Goal

Build and save combos of any channels (mods / viewers), pick them in the
chat bar next to "My chats", get suggested same-name matches on the other
platforms, jump into one platform from the combined view and back
("↩ Combined"), and pause YouTube polling while it's in the background.

## Design decisions (verified against the code)

- **Sources must live in the platform's own channel list.** "Shared"
  coupling means a combo selects channels on the platform stores, and each
  store only selects what its list holds (Twitch `channels` refs, YouTube
  `YouTubeUsernames` labels, Kick `KickUsernames` slugs). Saving a combo
  therefore **adds** each non-own source to that platform's list
  (Twitch `addChannel` without switching, YouTube / Kick settings entries +
  `reloadChannels`). That's intentional: a mod's channels show up in the
  single-platform dropdowns too. Removing a channel from a platform list
  leaves the combo source "missing" (status dot says so) instead of
  silently dropping it.
- **Combo model** (settings JSON, no Hive type): `CombinedCombo { id,
  name?, twitch?: {id, login, displayName}, youtube?: {label, value},
  kick?: {slug} }` in `SettingsKeys.CombinedChatCombos`; the selected one
  in `SettingsKeys.SelectedCombinedCombo` (`my` = "My chats", the default).
  A YouTube source stores its label + raw value so a missing entry can be
  re-created.
- **Suggestions (confirm-only):** after one source is picked, look up the
  same name on the empty platforms — Kick `resolveChannel(slug)`
  (anonymous, free), YouTube `@handle` via `parseYouTubeTarget` +
  `YouTubeEntryNamer` page title (free, no API quota), Twitch
  `searchChannels` (needs a Twitch login; exact login match only).
  Candidate names: the picked channel's login / slug / handle, lowercased,
  plus `_`↔`-` variants. Shown as tappable chips, never auto-filled.
- **Focus shortcut:** tapping a source dot in the combined view (status
  strip, new) switches the chat type to that platform with a transient
  `CombinedChatStore.focusedFrom` marker. The platform view then shows the
  combo's channel (the store already points there) and a "↩ Combined"
  chip; tapping it switches the type back. A focus switch does NOT run
  the restore (`deactivate(restore: false)`), and a later explicit
  type-switch away still restores (restore point kept).
- **Background rule:** while focused on a platform (or when the chat tab
  isn't Combined but a restore is pending), Twitch/Kick keep running;
  YouTube polling pauses via a new `YouTubeChatStore.pausePolling()` /
  `resumePolling()` pair (reuses `_stopPolling` / `connectChat`, keeps the
  buffer + page token).

## Tasks

1. **Combo model + persistence + store API** — `CombinedCombo`,
   load/save, `combos`, `selectedComboId`, `activeSources` (My chats →
   `mySources`, saved combo → its sources resolved against the stores;
   missing ones flagged), `saveCombo` (adds sources to platform lists),
   `deleteCombo`, `selectCombo` (re-activates when active). Timeline and
   status use `activeSources`. Tests.
2. **Suggestions** — `CombinedMatchFinder` (injectable services),
   candidate-name derivation, per-platform lookups with timeouts. Tests
   with fakes.
3. **Builder sheet** — `CombinedChatBuilderSheet` on
   `NativeChatSheetScaffold`: one row per platform (picker: own "You",
   channels already in that platform's list, "Other…" text field),
   suggestion chips, optional name, save (≥ 2 sources) / delete. Tests.
4. **Chat bar picker → dropdown** — "My chats" + saved combos + "New
   combined chat…"; long-press a saved combo → edit / delete. Tests.
5. **Focus shortcut + YouTube pause** — status strip in the combined view
   (tap = focus), `focusedFrom` + "↩ Combined" chip on the three native
   platform windows, `deactivate(restore:)`, YouTube pause/resume. Tests.
6. **Docs, full gate, self-review, push, dogfood install.**
