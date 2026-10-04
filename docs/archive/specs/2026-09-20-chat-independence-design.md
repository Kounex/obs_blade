# Chat independence — dedicated Chat tab (design, ratified 2026-09-20)

Astra progressive-adoption port. The audit's staging put "chat independence +
conversation-owned drafts" into the post-4.0 dashboard ports
(`docs/redesign-astra-audit.md` § Verdict). This wave lands **chat
independence** wearing the On Air/4.0 idiom; conversation-owned drafts are a
separate follow-up wave (user-ratified scope split 2026-09-20).

## Goal

Make chat usable **before/without an OBS session** and give it a full-screen
home, by adding a dedicated **Chat tab** — without regressing the live
workflow (the dashboard chat pane stays for co-display while live and tablet
side-by-side).

## Why a tab (ratified direction)

Exploration findings that shaped this:

- Chat **state** is already OBS-independent: `TwitchChatStore` /
  `YouTubeChatStore` are GetIt singletons, all chat config lives in the global
  Settings box (`SelectedChatType`, `SelectedTwitchUsername`,
  `YouTubeUsernames`, `YouTubeApiKey`, `SelectedChatEngine`), and the
  Twitch/YouTube connections (EventSub, API polling) never touch the OBS
  socket. An OBS disconnect already does not tear chat down.
- The dependency is purely **navigational**: the only chat surface
  (`StreamChat`) lives inside the dashboard route, and the dashboard route is
  only reachable after a connect (`lib/views/home/home.dart:179`
  push-replaces to `HomeTabRoutingKeys.Dashboard.route`).
- The single OBS coupling in the whole chat tree is one call:
  `DashboardStore.setPointerOnChat(...)` in
  `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart`
  (WebView scroll arbitration, audit defect #4) — only meaningful inside the
  dashboard's scroll view.
- Astra's no-routes shell was explicitly **not adopted** — the port must wear
  our routing idiom. A tab is exactly that: astra's "chat first-class,
  usable without OBS" translated into the existing tab scaffold.

Alternatives considered and set aside: session-decoupled dashboard (biggest
blast radius; every OBS pane needs an offline story; overlaps the just-landed
stale-state honesty work) and a global chat sheet/dock (gesture-risky against
the WebView arbitration, unidiomatic).

## Design

### 1. Tab scaffold

- `enum Tabs { Home, Chat, Statistics, Settings }` — Chat inserted at index
  1 (`lib/utils/routing_helper.dart`). Everything tab-related is enum-driven
  (tab bar items, `IndexedStack`, per-tab `Navigator`s, back-to-Home pop in
  `lib/tab_base.dart`), so insertion is mechanically safe. The active tab is
  in-memory only — no persisted state to migrate.
- `TabsFunctions`: name `'Chat'`, icon `CupertinoIcons.chat_bubble_2_fill`,
  routes `RoutingHelper.chatTabRoutes`.
- New `ChatTabRoutingKeys { Landing, Pro }` with routes `/tabs/chat` and
  `/tabs/chat/pro`; `RoutingHelper.chatTabRoutes` maps Landing → `ChatView()`
  and Pro → `ProPaywallView()`. The Pro entry is required: the native-chat
  upsell (`_ChatProUpsell`) pushes the paywall by route name, and that name
  must resolve on whichever tab navigator hosts the chat (pattern already
  exists on the Home and Settings tabs).
- The tab is **always visible**, like Statistics — the existing empty states
  (connect Twitch / set up YouTube) are the no-config experience.

### 2. `ChatView` (tab root)

New `lib/views/chat/chat_view.dart`:

- `Scaffold(body: TransculentCupertinoNavBarWrapper(title: 'Chat',
  customBody: ...))` — the landing-view idiom
  (`lib/shared/general/transculent_cupertino_navbar_wrapper.dart`); its
  `customBody` path exists for non-list bodies and owns the bar's top inset.
- Body: `StreamChat(usernameRowPadding: true)` wrapped in a centered
  `BaseConstrainedBox` (max 640,
  `lib/shared/general/base/constrained_box.dart`) — a no-op at phone widths
  (<640 = full-bleed) and the app's content-column cap on larger screens.
- Bottom clearance reuses the tab-bar formula
  `2 * kBottomNavigationBarHeight + MediaQuery.paddingOf(context).bottom / 2`
  (the `CustomSliverList` default, already reused by
  `lib/views/pro/widgets/pro_sales.dart`) so the chat input rests above the
  translucent tab bar.

### 3. `StreamChat` seams (both constructor params, defaults = today's
behavior)

- `scrollArbitration` (default `true`): when `false`, skip the `Listener` +
  `DashboardStore.setPointerOnChat` wrapper in `_buildLegacyChatStack` — the
  WebView owns its touches directly (no parent scroll view exists in the
  tab). The `DashboardStore` lookup in `build` becomes conditional on this
  flag. This is defect #4 *not applying* in the tab context, not a fix of
  the hardcoded band itself.
- `proRoute` (default `HomeTabRoutingKeys.Pro.route`): route name the
  `_ChatProUpsell` pill pushes. `ChatView` passes
  `ChatTabRoutingKeys.Pro.route`.

Everything else is reused untouched: WebView + native engines, Pro gate and
upsell, multi-chat bar, mod tooling, emote picker, login/setup sheets — all
context-local already.

### 4. Behavior

- **Pre-OBS:** the tab renders chat standalone. Native stores already connect
  on login restore / channel auto-select regardless of any surface; the
  WebView engine warms on first tab view. No store lifecycle changes.
- **While live:** the Home tab keeps the dashboard route alive in the
  `IndexedStack`; Dashboard ↔ Chat is one tap each way with full state
  preservation (scroll position, composer text — the tab never unmounts).
- **Dashboard pane untouched:** co-display while live and tablet side-by-side
  keep working exactly as today.
- **Back behavior:** the chat tab root has no back stack; Android back falls
  through to the existing "return to Home tab" logic in `tab_base.dart`.

## Non-goals (explicitly out of this wave)

- Conversation-owned drafts keyed by (platform, account, channel) — follow-up
  wave (store + composer work, own tests).
- Live-session strip (program pill + quick mic) in the chat tab bar — the
  astra focus-swap idea, parked as a phase-2 option.
- Any change to `TwitchChatStore` / `YouTubeChatStore`.
- Fixing defect #4's hardcoded Y band in the dashboard context.
- Removing or altering the dashboard chat pane.

## Edge cases

- **Pro upsell routing:** without the chat-tab Pro route registration +
  `proRoute` seam, tapping "Explore Pro" from the chat tab would push an
  unknown route on that navigator. Covered by design; test below.
- **No chat configured:** existing `_ChatEmptyState` per platform (connect
  Twitch CTA / YouTube setup sheet) renders in the tab unchanged.
- **Owncast:** WebView-only; works in the tab like anywhere else.
- **Not-Pro + native engine persisted:** the tab renders the same locked
  upsell pane as the dashboard would.

## Testing

New widget tests (under `test/chat/`, the chat area suite per AGENTS.md test
mapping):

1. `ChatView` renders the chat surface with no OBS session/stores touched —
  the independence proof (no-config empty state visible).
2. `scrollArbitration: false` skips the pointer Listener (WebView reachable
  directly; no `setPointerOnChat` interaction).
3. Upsell pill from the chat tab navigates to `ChatTabRoutingKeys.Pro.route`
  (paywall route registered on the chat navigator).
4. Tab scaffold sanity: `Tabs.Chat` has name/icon/routes wired (extension
  coverage).

Gates: `flutter test test/chat/` (+ any touched suites), `flutter analyze`
at exactly the 472-issue baseline, `dart format` on changed files. No
agent-side sim verification — the user dogfoods.

## Commit plan (per verified unit, on `4.0-liquid-glass`)

1. Tab scaffold + routes + `ChatView`.
2. `StreamChat` seams + widget tests.
3. Docs: changelog + handoff (drafts wave + session-strip option noted as
   follow-ups).

Sizing: **S-tier** (in-session, gates at the end).
