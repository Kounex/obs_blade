# Channel Mod actions (room sheet) — design

**Date:** 2026-08-09 · **Status:** approved (design), pre-plan · **Process tier:** S
(bump to M if scope-upgrade + settings polling prove multi-seam during planning)

## Intent

Per-message moderation (delete / timeout / ban) already lives on long-press.
Mods also need **channel-level** controls that are not tied to a user or
message: clear chat, chat modes, Shield Mode, and announcements. This design
adds a dedicated room **Mod actions** sheet, with an adaptive bar entry that
does not overflow small chat bars.

## Ratified decisions (from brainstorming)

| Question | Decision |
|---|---|
| Scope of v1 | **Full room panel**: clear + chat modes + shield + announce |
| Bar entry | **A1 adaptive**: dedicated shield when it fits; else options only |
| Fit rule | **F — measure the right cluster**: show bar shield only if options + shield + account fit without overflow |
| Narrow fallback | **Moderation…** row in Native chat options (same sheet) |
| Sheet structure | **A — single scroll sheet** + in-sheet steps (Announce compose; mode duration presets) |
| Confirmations | **Everything** — every final action confirms (including turning modes/shield off) |
| Announce UX | **In-sheet compose step** (chevron back; Send is the confirm) |
| Missing scopes | **Silent upgrade** — add manage scopes to `kTwitchChatScopes`; Clear works on current tokens; modes/shield/announce need re-login to unlock |

Rejected: always-on third bar button (overflows ~375pt phones); fixed width-only
breakpoint (long display names still overflow); modes-only in options with
destructive actions elsewhere (splits moderation).

## 1. Entry & visibility

**Gate** (all of):

- Native Twitch engine selected
- Logged in
- `TwitchChatStore.canModerateSelectedChannel` (same gate as the per-message
  mod sheet)

**Bar (wide / fitting):** 44pt shield control in the native right cluster of
`ChatUsernameBar`, beside `NativeChatOptionsButton` and `TwitchAccountControl`.
Visibility of the shield tile is **not** “screen width > N”; it is a **fit
check** on that cluster (LayoutBuilder / measure): show the shield only when
options + shield + account can lay out without overflow (respects long
display names and text scale).

**Options (always when gated):** Native chat options root gains a
**Moderation…** row that opens the same room sheet. Narrow phones rely on
this; wide layouts still keep it for discoverability.

**Hidden when:** WebView engine, logged out, or not moderating the effective
channel.

## 2. Sheet contents & interaction

Bottom sheet title reflects the effective channel (e.g. `Moderate #login` /
display name). One scrollable body; steps swap in-place (options-sheet /
Timeout… idiom: chevron + title, not a nested Navigator).

### Chat

| Action | Confirm | Helix | Local effect |
|---|---|---|---|
| Clear chat | Yes | `DELETE /moderation/chat` **without** `message_id` | Existing `/clear` path: tombstones + “Chat was cleared by a moderator” banner (same reconcile/dedup as EventSub clear) |

### Modes

Load **Get Chat Settings** when the sheet opens (and refresh if the
effective channel changes while open). Each row shows live on/off; changing
always confirms first.

| Mode | Notes |
|---|---|
| Emote-only | boolean |
| Subs-only | boolean |
| Unique chat | boolean |
| Followers-only | boolean; enabling opens a wait-preset step, then confirm naming the wait; disabling is confirm-only |
| Slow mode | boolean; enabling opens a delay-preset step, then confirm naming the delay; disabling is confirm-only |

Non-moderator chat delay: **out of v1** (YAGNI).

### Shield

| Action | Confirm | Helix |
|---|---|---|
| Shield Mode on/off | Yes (both directions) | Get/Update Shield Mode Status |

### Announce

Root row **Announce…** → compose step:

- MultILINE text field (Helix max 500; truncate or block send over limit —
  match Helix: truncate at send if we follow Twitch’s documented behavior,
  otherwise validate ≤500 in UI — pick **client validate ≤500** for clarity)
- Color chips: `primary`, `blue`, `green`, `orange`, `purple`
- **Send** is the confirming action (no second dialog); Cancel/back abandons
- Success: close the room sheet so chat shows the announcement

### Confirmations

Every final Helix mutation uses `ConfirmationDialog` (destructive styling
where appropriate). Cancel dismisses only the dialog; sheet stays open.
Re-entrancy: ignore double-taps while a mutation runs (same pattern as
`ModActionSheet`).

## 3. Scopes, API, store

### Scopes (`kTwitchChatScopes`)

| Scope | Capability |
|---|---|
| `moderator:manage:chat_messages` | Clear (already present); delete message (existing) |
| `moderator:manage:chat_settings` | **new** — get/update modes |
| `moderator:manage:shield_mode` | **new** — get/update shield |
| `moderator:manage:announcements` | **new** — send announcement |

Silent upgrade: new device logins consent to the expanded list; persisted
pre-upgrade tokens keep Clear (+ per-message mod). Modes / Shield / Announce
are unavailable until re-login — tapping them uses the established
**Re-login** device-code path (same idea as write/emotes CTAs), not a
dedicated lock-strip layout inside the sheet.

Capability getters on `TwitchChatStore` (plain, like `canWriteChat`):
`canManageChatSettings`, `canManageShieldMode`, `canSendAnnouncements`
(or one bundled “room controls” getter if all three ship together — prefer
**per-scope getters** so partial upgrades degrade cleanly).

### Services

Extend `TwitchModerationService` (or a focused `TwitchChatSettingsService` if
the file grows too large) with:

- `clearChat` (delete all messages)
- `getChatSettings` / `updateChatSettings`
- `getShieldModeStatus` / `updateShieldModeStatus`
- `sendChatAnnouncement`

Injectable `http.Client` for tests (existing pattern).

### Store behavior

- Sheet open → fetch settings (+ shield status) for `effectiveBroadcasterId`
- After successful update → patch local snapshot so toggles stay correct
  without waiting for EventSub
- Failures → snackbar via caller context (sheet may already be mid-confirm);
  do not flip local toggle state
- Clear → call Helix then apply the same local clear helper EventSub uses
  (explicit local apply after success so UI updates even if EventSub is
  slow; existing dedup keys prevent double banners)

## 4. UI placement (files)

| Piece | Where |
|---|---|
| Fit-based shield button | `chat_username_bar.dart` (+ small widget next to options) |
| Options “Moderation…” | `native_chat_options_sheet.dart` |
| Room sheet + announce step | new `dialogs/channel_mod_sheet.dart` (alongside `mod_action_sheet.dart`) |
| Confirms | existing `ConfirmationDialog` + `ModalHandler` |

Visual language: same card rows / 44pt targets / status red for destructive
as `ModActionSheet` and connection sheet.

## 5. Testing

- Fit check: shield present when cluster wide enough; absent when forced
  narrow (pump with tight width / long display name)
- Options row opens the same sheet type
- Clear: Helix called without `message_id`; local clear + banner; confirm
  cancel does nothing
- Mode/shield: confirm then Helix; failure snackbar, state unchanged
- Announce step: validate length; send closes; missing scope → re-login CTA
- Pre-upgrade token: Clear still offered; manage actions gated

## 6. Out of scope (v1)

- AutoMod / blocked terms / unban-request queues
- VIP/mod role management
- Non-moderator chat delay
- Per-user warn from this sheet (stays on message/user flows)
- WebView engine parity

## 7. Process

Tier **S** default: implement in-session after plan; gates once at end.
Escalate to **M** only if silent-upgrade + settings fetch + fit layout
warrant a split implementer/reviewer.
