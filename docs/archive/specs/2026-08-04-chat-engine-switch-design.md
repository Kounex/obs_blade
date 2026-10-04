# Chat Engine Switch — Control Section Redesign (Design Spec)

**Date:** 2026-08-04
**Status:** Approved (design), pre-plan
**Context:** Native Twitch chat Phase 1 (device-code login + read-only EventSub chat) shipped the same day. Its account chip landed inside the classic WebView username action row, mixing the two worlds. This redesign separates them cleanly around an explicit **chat engine** concept.

## Goal

Restructure the dashboard chat control section so that:

1. The **platform selector** (Twitch / YouTube / Owncast) remains the single major control.
2. **WebView username controls** (username dropdown + add/edit/delete) are grouped with it, unchanged from the classic behavior.
3. A **manual toggle switches the chat engine** (WebView ↔ Native) — Native exists only for Twitch — and only engine-appropriate actions are visible: native shows login/logout + the connected account, never the username controls.

Non-goals (YAGNI): the availability/entitlement gate for native chat (a separate future feature), auto-switching engines on login (arrives with that gate), native engines for YouTube/Owncast, sending messages, badges, chat container restyle.

## Behavior model

- New persisted setting `SettingsKeys.SelectedChatEngine` in the Settings box, enum `ChatEngine { webView, native }` (`lib/models/enums/chat_engine.dart`, mirroring `chat_type.dart` — which is a full `@HiveType` enum persisted directly in the Settings box, so `ChatEngine` is one too). Default: `webView` — existing installs see zero behavioral change (a missing key falls back to the default at read time, same as `ChatType`).
- The engine is a single app-wide key (only Twitch has a second engine; per-platform keys are YAGNI until another platform goes native).
- Fully manual toggle. No auto-switch on login, logout, or cold start in this iteration.
- **Availability seam (documented, not built):** one top-level function — `nativeChatAvailableFor(ChatType chatType)` in `lib/models/enums/chat_engine.dart`, returning `chatType == ChatType.Twitch` today — is the single place a future entitlement check (and the auto-switch-on-login it brings) will plug into. The switch's visibility and every engine read go through it.
- EventSub connection lifecycle is engine-independent: while logged in, `TwitchChatStore` keeps its connection alive regardless of the selected engine, so switching engines is instant and the state machine stays untouched. No `DashboardStore` changes.

## Control section layout (`chat_username_bar.dart`)

The bar keeps its two-column shape:

```
[Platform ▾    ]   [WebView | Native]      <- engine switch (Twitch only)
[Username ▾    ]   [ + | ✎ | 🗑 ]          <- WebView mode actions
```

Native mode (Twitch):

```
[Platform ▾    ]   [WebView | Native]
                   [ ✓ Kounex ]            <- account chip, or [ Connect Twitch ] pill when logged out
```

- **Left column:** platform dropdown (always); username dropdown only in WebView mode.
- **Right column, top:** `ChatEngineSwitch` — a `CupertinoSlidingSegmentedControl<ChatEngine>` ("WebView" / "Native", text-only), the established pattern (`switcher_card.dart`, statistics controls). Visible only when the selected platform has a native engine; hidden entirely for YouTube/Owncast.
- **Right column, bottom:** mode-specific actions:
  - **WebView:** the classic username action row (add/edit/delete), exactly as today. The Twitch account chip/Observer is **removed** from this row (it was the mixing point).
  - **Native:** `TwitchAccountControl` — logged in → account chip (checkmark + display name, tap → "Disconnect Twitch?" confirmation, as shipped in `b3f69d4`); logged out → a "Connect Twitch" pill (same visual style as the empty-state pill).

## Slot rendering (`stream_chat.dart`)

- Native view renders iff `chatType == Twitch && engine == native && isLoggedIn`.
- `native && logged out` → connect-oriented empty state: brand icon, "Connect your Twitch account to see your chat natively." copy, and the "Connect Twitch" pill (relocated from the WebView empty state).
- `engine == webView` → the legacy WebView stack exactly as today, **regardless of login state** (a logged-in user can deliberately use the classic chat). Its empty state reverts to the username prompt only ("No Twitch username selected…") — the connect pill lives exclusively in native mode.
- The post-logout legacy-WebView reload behavior (unchanged-URL early-return in `_syncWebController`) is unaffected by this redesign and stays on the open-verification list.

## Files

- **New:** `lib/models/enums/chat_engine.dart` — `@HiveType(typeId: TypeIDs.ChatEngine)` enum with `@HiveField(0) webView` / `@HiveField(1) native` + a `text` extension ("WebView" / "Native"), mirroring `chat_type.dart` including its generated adapter (`part 'chat_engine.g.dart'`, build_runner). Also hosts the **availability seam** as a top-level function `bool nativeChatAvailableFor(ChatType chatType)` (today: `chatType == ChatType.Twitch`) — the engine switch's visibility and all engine reads go through it, so the future entitlement gate has exactly one call site to extend.
- **Modified:** `lib/models/type_ids.dart` — append `ChatEngine = 14` (13 is `TwitchAuth`, the current max; never renumber existing IDs).
- **Modified:** `lib/main.dart` — manual `Hive.registerAdapter(ChatEngineAdapter())` in `_initializeHive` next to the other enum adapters (never the generated registrar).
- **Modified:** `test/persistence/support/hive_test_harness.dart` — same guarded adapter registration for tests.
- **New:** `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/chat_engine_switch.dart` — the segmented control; reads/writes `SelectedChatEngine` in the Settings box.
- **New:** `lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/twitch_account_control.dart` — account chip + connect pill + disconnect confirmation.
- **Modified:** `chat_username_bar.dart` — two-column restructure (left: platform [+ username in WebView mode]; right: engine switch + mode actions); add `SelectedChatEngine` to the `HiveBuilder` rebuildKeys.
- **Modified:** `username_action_row.dart` — back to pure WebView controls (remove account chip/Observer/Twitch-only branch; the `_UsernameAction` `label` support moves with the chip to `twitch_account_control.dart`).
- **Modified:** `stream_chat.dart` — slot branch per the rendering rules; empty states split (native connect prompt vs WebView username prompt).
- **Modified:** `lib/types/enums/settings_keys.dart` — add `SelectedChatEngine`.
- Data-management wipes: no changes needed — the engine key lives in Settings and is covered by the existing "All Data" wipe; the Twitch wipe stays credential-only.

## Error handling / edge cases

- `native && logged out` and the user cancels or the login errors: they stay on the native connect prompt; the dialog already surfaces errors inline.
- `native` selected, then the Twitch box is wiped (data management) → store resets to logged out → native connect prompt. Consistent.
- Switching engines mid-connect-flow: the dialog is modal and self-contained; on completion the slot renders per the current engine. No extra handling.
- Long display names: the account chip already ellipsizes at 96 px.
- Tablet/desktop layouts use the same bar — no responsive fork in this redesign.

## Testing

Update/extend `test/chat/twitch_chat_integration_test.dart`:

- Slot per engine: `webView + logged in` → legacy stack (WebView path preserved); `native + logged out` → connect empty state with pill; `native + logged in` → `NativeTwitchChatView`.
- Engine switch: hidden for YouTube/Owncast; visible for Twitch; tapping "Native"/"WebView" swaps the visible controls (username row vs account chip/connect pill) and persists the key.
- Persistence: engine key round-trips; default is `webView` when unset.
- Move the account-chip/disconnect-dialog assertions to the native-mode control; keep the copy-feedback dialog test as-is.

Quality gates: full `flutter test` green, `flutter analyze` at 0 errors + only the 6 pre-existing warnings, no new dependencies, no `DashboardStore` changes.

## Out of scope (recorded for later)

- Native-chat availability gate (entitlement) + auto-switch-on-login — future feature; the `ChatEngineSupport` seam is where it lands.
- Mobile chat "window/container" UI (needed by the Phase 2 send input), badges + per-category toggles, 7TV/BTTV emotes, revocation toast, `messageId` dedup, refresh-400 mid-session handling.
