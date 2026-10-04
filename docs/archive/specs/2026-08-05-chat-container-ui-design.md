# Native chat window — container, status row & connection sheet (design)

Date: 2026-08-05 · Status: approved design (pre-plan) · Track: native Twitch chat, Phase 3 (container UI)

## Context

The native Twitch chat renders bare in the dashboard chat slot — on mobile
(Chat+Stats tab view, `obs_widgets_mobile.dart`) there is no visual container
around it, unlike tablet where the slot sits in a titled `BaseCard` (the "own
box" the user explicitly likes). The user asked for "a nice ui as the chat
'window / container'", also as the future home of the chat input field.

Visual direction was picked from browser mockups (visual companion,
`.superpowers/brainstorm/`): **inset pane** (soft fill + hairline) with a
**slim status row** inside its top edge — the status being **always
tappable**, opening a connection sheet that shows account/uptime when
healthy and diagnostics + actions when degraded.

## Decisions (from brainstorming)

- **Native engine only.** WebView embeds stay bare — zero risk to that path.
- **Wrapper widget** — the window is a separate widget wrapping the existing
  native content; `NativeTwitchChatView` and the connect prompt stay
  untouched internally.
- **Reusable by construction** — the window takes plain params (branding via
  `ChatType`, a generic connection-status enum, strings, callbacks), never
  Twitch store types. The Twitch call site maps store state → params; a
  future native YouTube engine reuses the widget with its own mapping.
  (User: "different branding but hopefully a lot to reuse".) **No** abstract
  engine interface beyond this param seam (YAGNI with one implementer).
- **Status row always tappable** — sheet shows account + uptime when healthy,
  diagnostics (last error, Retry, Logout) when degraded, a Connect action
  when logged out.
- **Applies everywhere the native engine renders** — mobile tab slot,
  standalone mobile card, tablet card, streaming mode — for consistency.
- **Input dock is layout-reserved only** — the pane is designed with a bottom
  slot in mind; no input field is built in this phase.

## Verified code facts

- Native branch: `stream_chat.dart:230-244` — an `Observer` returning
  `NativeTwitchChatView` when `TwitchChatStore.isLoggedIn`, else
  `_ChatEmptyState(nativeConnectPrompt: true)`. The window wraps exactly
  this branch.
- `TwitchChatStore` exposes everything the sheet needs:
  `chatConnection` (`disconnected | connecting | live | reconnecting |
  failed`), `chatError`, `user` (`TwitchUser{login, displayName}`),
  `connectChat()` (retry), `logout()`. Only gap: no "connected since"
  timestamp → small store addition (`chatConnectedAt`).
- Pane idiom already used by every chat bar control
  (`chat_type_dropdown.dart:28-31`, `username_dropdown.dart:55-58`,
  `username_action_row.dart:40-43`, `twitch_account_control.dart:77-80`,
  `native_chat_options_sheet.dart:39-42`):
  `StylingHelper.lightenDarkenColor(Theme.of(context).cardColor)` fill,
  hairline `Theme.of(context).dividerColor.withValues(alpha: 0.4)` border.
- Branding seam exists: `ChatType` carries `.text`, `.icon`, `.brandColor`
  (used by `_ChatEmptyState` / `_ChatLoadingState`).
- Bottom-sheet pattern: `ModalHandler.showBaseBottomSheet` (used by
  `native_chat_options_sheet.dart`).
- Tablet interplay: the tablet slot is `BaseCard(title: 'Chat', …)` — the
  window nests *inside* that card, so the status row's left label is the
  platform name ("Twitch"), not "Chat" (avoids title duplication).

## Architecture

### 1. `NativeChatWindow` widget

New file
`lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart`:

- **Params:** `chatType` (branding: label/icon/color), `status`
  (`NativeChatConnectionStatus`), `statusDetail` (`String?` — error text for
  the sheet), `accountLabel` (`String?` — display name when logged in),
  `connectedAt` (`DateTime?`), `onRetry` / `onLogout` / `onConnect`
  (`VoidCallback?` — sheet actions, null hides the action), `child`.
- **Generic status enum** defined in this file:
  `NativeChatConnectionStatus { offline, connecting, live, reconnecting,
  failed }` — platform-agnostic; each engine maps its store enum onto it.
- **Layout:** `Container` (pane idiom above, `AppRadius.md`) → `Column`:
  status row, hairline `BaseDivider`-style separator, `Expanded(child)`.
  The pane clips to its radius (`Clip.antiAlias` via decoration).
- **Status row:** min height ≥44pt (tap target), horizontal
  `AppSpacing.md` padding: left = platform glyph (`chatType.icon`, brand
  color, small) + platform label (`chatType.text`,
  `textTheme.bodySmall`); right = `Pressable` state pill: colored dot +
  label (`connected` / `connecting…` / `reconnecting…` / `failed` /
  `offline`), colors: live → green (`Colors.green`-family token already
  used in app for live states), connecting/reconnecting → amber, failed →
  red, offline → muted. Whole row is the tap target (opens the sheet).
- **No layout surgery elsewhere** — the pane simply fills the slot it's
  given in every host (tab view, cards, streaming mode).

### 2. Connection sheet

Same file (private widget or small sibling file if it grows):

- Opened via `ModalHandler.showBaseBottomSheet`, title = platform label.
- **Healthy (`live`):** account row (display name / `accountLabel`) and a
  connected-for uptime line (derived from `connectedAt`, compact
  `hh:mm`/`mm:ss` formatting). Nothing else — no message counts, no stats.
- **Degraded (`connecting` / `reconnecting` / `failed`):** `statusDetail`
  text when present, **Retry** (`onRetry`) and **Logout** (`onLogout`)
  actions (full-width rows, existing sheet-row idiom).
- **Logged out (`offline`):** explanatory line + **Connect** (`onConnect`)
  action.
- **Logout confirms** — the sheet's Logout action routes through the same
  `ConfirmationDialog` the account chip uses
  (`twitch_account_control.dart:59-67`), then calls `logout()`.

### 3. Wiring in `stream_chat.dart`

- The native branch wraps both states:
  `NativeChatWindow(…, child: isLoggedIn ? NativeTwitchChatView() :
  _ChatEmptyState(nativeConnectPrompt: true))`.
- Mapping (Twitch → generic) lives at this call site:
  `disconnected → offline`, `connecting → connecting`, `live → live`,
  `reconnecting → reconnecting`, `failed → failed`; `statusDetail =
  chatError`; `accountLabel = user?.displayName ?? user?.login`;
  `connectedAt = store.chatConnectedAt`; callbacks → `connectChat()` /
  `logout()` / `startTwitchLogin(context)`.
- The `Observer` already at the branch rebuilds on all of these
  (observables: `chatConnection`, `chatError`, `user`, `chatConnectedAt`).

### 4. `TwitchChatStore` addition (only non-UI change)

- `@observable DateTime? chatConnectedAt` — set in `_onEventSubState` on
  transition **to** `live` from a non-live state (not on every live event);
  cleared in `_disconnectChat()` and on `failed` transitions.
- No `DashboardStore` changes. No persistence (in-memory only).

### 5. Interaction with existing in-view states

`NativeTwitchChatView`'s center states stay: the zero-message
connecting spinner and the failed + Retry screen remain the *content-area*
states; the status row is the always-visible chrome. They complement, not
duplicate (row = at-a-glance state; center = blocking state with details).

## Error handling & edge cases

- **Logged out:** status `offline`; sheet offers Connect (device flow) —
  same entry as the prompt's button, no new flow.
- **Reconnect storm (background recovery):** status flips
  reconnecting → live; `chatConnectedAt` resets on each fresh `live` — the
  sheet always shows the current session's uptime.
- **Auth revoked mid-session:** store already resets to logged out →
  window shows `offline` + connect prompt in content — no new handling.
- **Failed with messages still in buffer:** status row shows `failed` while
  old messages stay visible — intended (matches today's in-view behavior).
- **Tablet card nesting:** pane inside `BaseCard(title: 'Chat')` — platform
  label prevents "Chat / Chat" duplication.
- **Force Tablet Mode / phone:** same widget, no breakpoints.

## Testing

- **Unit** (`test/chat/`):
  - `chatConnectedAt`: set on →live transition, not re-set on repeated
    live, cleared on disconnect/failed (existing store test seams:
    `eventSubFactory` fake).
- **Widget**:
  - Window renders status label per state (all five), correct dot color
    token, row meets ≥44pt tap target.
  - Tap opens sheet: healthy shows account + uptime; degraded shows error
    + Retry/Logout (callbacks fire); offline shows Connect.
  - Mapping function: every `TwitchChatConnectionState` → expected
    `NativeChatConnectionStatus`.
- Gates: `flutter analyze` (0 errors; pre-existing warning baseline
  unchanged), full `flutter test` green.

## Out of scope (explicit)

- Chat input / sending (dock reserved in layout only).
- WebView-engine container of any kind.
- Native YouTube engine itself (reusability seam only).
- 7TV/BTTV/FFZ, entitlement gating, badge changes.
- Persistence of uptime/connection history.

## Docs hygiene

No credentials, user ids, or LAN details in code, tests, or docs.
