# Channel Mod Actions (Room Sheet) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps
> use checkbox (`- [ ]`) syntax for tracking. **Process tier: S** — implement
> in-session (or one implementer if splitting), gates once at the end.
> Spec: [`docs/superpowers/specs/2026-08-09-channel-mod-actions-design.md`](../specs/2026-08-09-channel-mod-actions-design.md)

**Goal:** Add a channel-level Mod actions sheet (clear chat, chat modes,
Shield Mode, announce) with adaptive bar entry that does not overflow the
native chat username bar on small phones.

**Architecture:** Extend `TwitchModerationService` with Helix clear-all,
chat settings get/update, shield get/update, and announcements. Store
methods + scope getters on `TwitchChatStore`. New `ChannelModSheet` UI
(scroll + in-sheet steps) opened from a fit-checked shield button and from
Native chat options. Every final action uses `ConfirmationDialog`.

**Tech Stack:** Flutter, MobX, GetIt, `package:http` MockClient tests,
existing `ConfirmationDialog` / `ModalHandler` / sheet chrome.

---

## Global Constraints

- New scopes on `kTwitchChatScopes` (silent upgrade):
  `moderator:manage:chat_settings`,
  `moderator:manage:shield_mode`,
  `moderator:manage:announcements`.
- Clear uses existing `moderator:manage:chat_messages` (omit `message_id`).
- Gate entry with `canModerateSelectedChannel` (native + logged in + mod).
- Bar shield: **fit check** on the right cluster — not a fixed width
  breakpoint. Options always get **Moderation…** when gated.
- Confirm **every** final Helix mutation (including turning modes/shield
  off). Announce **Send** is the confirm (no second dialog).
- After successful clear: call `applyChatClear()` (existing dedup/banner).
- Do not flip local mode/shield state on Helix failure; snackbar on failure.
- Injectable `http.Client`; no real HTTP in unit tests.
- Commit per task. Do **not** push unless asked.
- Flutter: workstation `~/.dotfiles/flutter/sdk` or `./flutterw`; headless
  clone uses `~/flutter`.

## File map

| File | Responsibility |
|---|---|
| `lib/utils/twitch/twitch_auth_service.dart` | New scopes on `kTwitchChatScopes` |
| `lib/utils/twitch/twitch_moderation_service.dart` | Helix clear / settings / shield / announce |
| `lib/types/classes/twitch/chat_settings.dart` | Immutable DTO for Get/Update Chat Settings fields we use |
| `lib/stores/views/twitch_chat.dart` | Scope getters + store actions + optional settings snapshot |
| `lib/views/.../dialogs/channel_mod_sheet.dart` | Room sheet UI + steps + confirms |
| `lib/views/.../chat_username_bar.dart` | Fit-based shield button in right cluster |
| `lib/views/.../native_chat_options_sheet.dart` | Moderation… row |
| `test/chat/twitch_moderation_service_test.dart` | Service HTTP contracts |
| `test/chat/twitch_chat_store_test.dart` | Store actions / scope gates |
| `test/chat/channel_mod_sheet_test.dart` | Sheet confirms + clear / mode / announce |
| `test/chat/channel_mod_entry_test.dart` | Fit shield + options row |

## Presets (lock these values)

**Follower wait (minutes):** `0, 10, 30, 60, 1440, 10080, 43200`
(0 / 10m / 30m / 1h / 1d / 1w / 1mo — Twitch max is 129600).

**Slow delay (seconds):** `3, 5, 10, 30, 60, 120` (Helix allows 3–120).

**Announce colors:** `primary`, `blue`, `green`, `orange`, `purple`;
message max **500** chars (block Send if empty or `> 500`).

---

### Task 1: Scopes + Helix service methods

**Files:**
- Modify: `lib/utils/twitch/twitch_auth_service.dart` (`kTwitchChatScopes`)
- Modify: `lib/utils/twitch/twitch_moderation_service.dart`
- Create: `lib/types/classes/twitch/chat_settings.dart`
- Test: `test/chat/twitch_moderation_service_test.dart` (extend)
- Test: auth scope list expectation wherever `kTwitchChatScopes` is asserted

- [ ] **Step 1: Failing tests for clearChat (no message_id), get/update
  settings, shield, announce**

Assert:

- `clearChat` → `DELETE .../moderation/chat?broadcaster_id=&moderator_id=`
  (no `message_id`), 204
- `getChatSettings` → `GET .../chat/settings?...` parses
  `emote_mode`, `follower_mode`, `follower_mode_duration`,
  `subscriber_mode`, `slow_mode`, `slow_mode_wait_time`,
  `unique_chat_mode`
- `updateChatSettings` → `PATCH` JSON body with only the fields passed
- `getShieldModeStatus` / `updateShieldModeStatus` → Helix shield endpoints
  (`GET`/`PUT` `moderation/shield_mode`)
- `sendChatAnnouncement` → `POST .../chat/announcements` with
  `{message, color}`, 204

- [ ] **Step 2: Implement DTO + service methods**

```dart
class TwitchChatSettings {
  final bool emoteMode;
  final bool followerMode;
  final int? followerModeDurationMinutes;
  final bool subscriberMode;
  final bool slowMode;
  final int? slowModeWaitTimeSeconds;
  final bool uniqueChatMode;
  // fromJson / copyWithWithUpdates as needed
}
```

Extend `TwitchModerationService` doc comment for the new scopes.

- [ ] **Step 3: Add the three scopes to `kTwitchChatScopes`; fix scope
  string tests**

- [ ] **Step 4: Run** `flutter test test/chat/twitch_moderation_service_test.dart`
  (and any auth scope test). **Commit:**
  `feat(chat): Helix clear/settings/shield/announce + room mod scopes`

---

### Task 2: Store actions + capability getters

**Files:**
- Modify: `lib/stores/views/twitch_chat.dart`
- Test: `test/chat/twitch_chat_store_test.dart`

- [ ] **Step 1: Failing tests**

- `canManageChatSettings` / `canManageShieldMode` / `canSendAnnouncements`
  true only when the matching scope is on the persisted token
- `clearSelectedChannelChat()` → moderation clear + `applyChatClear()`;
  returns `false` on service throw (no clear applied)
- `updateSelectedChatSettings(...)` / `setShieldMode(bool)` /
  `sendAnnouncement(message, color)` return bool; update an
  `@observable TwitchChatSettings? roomChatSettings` (and shield bool)
  only on success
- `refreshRoomModState()` loads settings + shield for
  `effectiveBroadcasterId`

- [ ] **Step 2: Implement** using existing token/user/`effectiveBroadcasterId`
  patterns from `deleteMessage` / `banUser`. Inject nothing new if
  `_moderationService` already covers the methods.

- [ ] **Step 3: Run store tests. Commit:**
  `feat(chat): store room mod actions and scope getters`

---

### Task 3: `ChannelModSheet` UI (clear, modes, shield, announce)

**Files:**
- Create: `lib/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_mod_sheet.dart`
- Create: `test/chat/channel_mod_sheet_test.dart`
- Reuse chrome from `mod_action_sheet.dart` / `native_chat_chrome.dart`

- [ ] **Step 1: Failing widget tests** (mirror `mod_action_sheet_test.dart`
  harness: GetIt store + fake moderation service)

- Open sheet → title contains channel name; sections visible
- Clear → confirm → service clear + sheet closes + `applyChatClear` effect
- Cancel confirm → no Helix call; sheet still open
- Toggle emote-only off→on → confirm → update settings
- Followers-only enable → preset step → confirm with minutes
- Shield on → confirm → update shield
- Announce… → compose → Send with color → sendAnnouncement; sheet closes
- Missing `canManageChatSettings` → modes/announce/shield offer re-login
  (or are omitted per spec silent-upgrade; **prefer: show rows, tap starts
  `startTwitchLogin` / existing re-login helper**); Clear still works

- [ ] **Step 2: Implement sheet**

States: `root | followerPresets | slowPresets | announceCompose`.

Root: scrollable sections Chat / Modes / Shield / Announce.
Each destructive or toggle action → `_confirmThenRun` (copy from
`ModActionSheet`).
Announce compose: `NativeChatTextField` (or existing field), color chips,
Send disabled if empty or `length > 500`.

`showChannelModSheet(BuildContext context)` like `showModActionSheet`.

On open: `store.refreshRoomModState()`.

- [ ] **Step 3: Tests green. Commit:**
  `feat(chat): channel Mod actions sheet with confirm-all`

---

### Task 4: Adaptive entry (fit shield + options row)

**Files:**
- Modify: `lib/views/.../chat_username_bar.dart/chat_username_bar.dart`
- Create: `lib/views/.../channel_mod_button.dart` (or inline in bar)
- Modify: `lib/views/.../native_chat_options_sheet.dart`
- Test: `test/chat/channel_mod_entry_test.dart`

- [ ] **Step 1: Failing tests**

- When `canModerateSelectedChannel` and pumped at a **wide** width with a
  short display name → find shield (e.g. `CupertinoIcons.shield` /
  `shield_fill`) and options
- When forced **narrow** (tight `MediaQuery` / long display name so the
  cluster cannot fit three controls) → **no** shield; options still present
- Options sheet contains **Moderation…**; tap opens `ChannelModSheet`
- WebView / not moderating → no shield, no Moderation… row

- [ ] **Step 2: Implement fit check**

In the native right `Row` (options + account):

```dart
// Pseudocode — measure preferred widths; show shield only if
// optionsW + gap + shieldW + gap + accountW <= maxWidth
LayoutBuilder(
  builder: (context, constraints) {
    final showShield = canMod && fits(constraints.maxWidth);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showShield) ...[ChannelModButton(), SizedBox(width: AppSpacing.sm)],
        NativeChatOptionsButton(...),
        SizedBox(width: AppSpacing.sm),
        TwitchAccountControl(), // account text already maxWidth 96
      ],
    );
  },
);
```

Prefer measuring with `TextPainter` / known 44pt tile sizes over a magic
screen breakpoint. If `TwitchAccountControl` is unbounded in the row, wrap
account in `Flexible` so the row can compress before hiding the shield.

Add **Moderation…** to options root (Twitch native only, same gate),
chevron row like Appearance.

- [ ] **Step 3: Tests green. Commit:**
  `feat(chat): adaptive Mod entry — fit shield + options row`

---

### Task 5: Gates + docs touch-up

- [ ] **Step 1:** `flutter test test/chat/` (at least the new/changed files;
  full `test/chat` preferred)
- [ ] **Step 2:** `flutter analyze` on touched libs — no new errors
- [ ] **Step 3:** Update `docs/session-handoff.md` / `AGENTS.md` Chat
  blurb only if the handoff still lists “replies/announce” as next without
  room mod — one short bullet that room Mod sheet shipped (or is WIP)
- [ ] **Step 4:** Final commit if doc-only:
  `docs: note channel Mod actions sheet`

---

## Execution notes

- Keep per-message `ModActionSheet` untouched except shared confirm helpers
  if you extract `_confirmThenRun` (optional DRY; YAGNI if copy is smaller).
- Do not implement AutoMod, blocked terms, VIP/mod management, or
  non-moderator chat delay.
- Announce success closes the **room sheet** (spec §2).
