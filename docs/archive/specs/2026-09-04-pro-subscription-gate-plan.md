# Plan — Pro subscription gate for native chat (2026-09-04)

**Tier: L** — multi-subsystem (IAP/entitlement/persistence + new paywall UI +
gating across the chat surface). Strategy source (binding):
`docs/private/monetization-strategy.md` — free core forever (WebView chat
stays free), Pro = subscription **paired with a lifetime buy-out**, no
monetization interrupts during an active session (all entry points are
user-initiated taps), transparent cancel, foss branch degrades to absent.
Named constraints: `plan-defect-checklist.md` §2/§3 apply to every task.

## Product shape (fixed)

- Product id constants (single source, `lib/utils/pro_ids.dart` or similar —
  verifier picks the idiomatic spot): `pro_yearly` (subscription, hero),
  `pro_monthly` (subscription), `pro_lifetime` (non-consumable). Empty-fill
  constants pattern like `kYouTubeOAuthClientId`: the ids ARE the final
  strings (we control them store-side later) but the store products don't
  exist yet — every store query may legitimately return nothing.
- **Entitlement = "Pro".** Gates: native chat engines (Twitch + YouTube).
  Free forever: WebView chat, all OBS control.
- **Entitlement truth:** settings-box flag (`SettingsKeys.BoughtPro`-style)
  set on purchase/restored events in `PurchaseBase` + **cold-start restore
  via `InAppPurchase.instance.restorePurchases()`** once per install
  (guarded — `queryPastPurchases` was REMOVED in in_app_purchase 3.3.0;
  restore emits past purchases on the stream as `PurchaseStatus.restored`)
  + explicit Restore button on the paywall. **Silent vs explicit restore:**
  the blacksmith restored branch shows a success dialog assuming the user
  tapped Restore — the cold-start path must NOT show it. `PurchaseBase`
  distinguishes: explicit-restore flag set by the paywall's Restore button
  → dialog; cold-start restore → silent flag set. Client-side expiry
  detection for lapsed subscriptions is NOT solvable with `in_app_purchase`
  alone — documented limitation; server-side receipt validation /
  RevenueCat is the backend wave's job (monetization-strategy already
  decided "entitlements bought not built"). A `ProStore` (MobX, GetIt)
  exposes `isPro` as an observable over the box + a debug override
  (`kDebugMode` only, settings key, hidden long-press toggle in the
  paywall or settings — implementer picks, document it).
  **PurchaseBase robustness:** guard the `queryProductDetails(...)`
  `.productDetails.first` call for empty results (pro ids don't exist
  store-side yet — a purchase event would otherwise throw StateError and
  the flag silently never sets).
- **Graceful degradation (products don't exist yet):** paywall renders the
  full benefits experience with pricing cards in a placeholder state
  ("Price shown at purchase" / disabled buy with a friendly toast); store
  query errors → toast + logged, never crash. Non-iOS/Android → same
  placeholder state.
- **foss:** all new code additive; the foss branch strips billing later
  (changelog note), nothing breaks when IAP is absent.

## UX (the "experience")

Paywall = **full-screen route** (decided — NOT a dialog; the Blacksmith
dialog is precedent only for the loading/error/priced/purchased state
machine and restore idiom), On Air design system (tokens, `Pressable`,
`StaggeredEntrance`, 250ms fade+scale):
hero section (Pro branding, app accent), browsable benefit cards (native
Twitch chat — read AND write from your phone; native YouTube chat incl.
Super Chat rendering; phone-native moderation: delete/timeout/ban; more Pro
features coming — health alerts, platform tools), horizontal card carousel
with `smooth_page_indicator` (already a dependency) or vertical cards —
implementer follows the design system, whichever reads better on phone +
tablet (ResponsiveWidgetWrapper if composition differs). Pricing section:
yearly (hero, "best value"), monthly, lifetime — rendered from live
`ProductDetails` when available, placeholder otherwise. Restore purchases +
terms/privacy link-outs. Success: confetti (`confetti` already a
dependency) + entitlement unlock. Never auto-presented; only from
user-initiated entry points.

Entry points:
1. Chat-bar engine switch — Native segment shows a lock badge when not Pro;
   tapping it opens the paywall (does NOT switch engine).
2. Native chat panes (`stream_chat.dart` native branches) — not-Pro →
   upsell pane (compact benefits preview + "Explore Pro" → paywall)
   instead of the login/setup CTA.
3. Settings — new "OBS Blade Pro" row/section (status when Pro: thank-you
   state + manage-subscription link-out; when not: opens paywall).

## Tasks

### Task 1 — entitlement core
- Product id constants; `SettingsKeys` additions (`lib/types/enums/
  settings_keys.dart` conventions incl. `name` map): `BoughtPro` (bool),
  `ProDebugOverride` (bool, debug-only consumption).
- `lib/stores/pro_store.dart` (MobX, GetIt-registered in `lib/main.dart`
  mirroring other stores): `isPro` observable (box watcher + debug
  override), `products` (ProductDetails from `queryProductDetails`,
  loaded lazily by the paywall), `buy(product)`, `restore()`,
  error/pending observables for the paywall UI. Injectable
  `InAppPurchase` instance seam for tests (check how the package allows
  faking; if it can't be injected cleanly, wrap the static calls in a thin
  injectable `ProPurchaseService` and test that instead).
- `PurchaseBase` wiring: pro product ids → set `BoughtPro` on
  purchased/restored (explicit-restore → restored InfoDialog idiom;
  cold-start restore → silent); `completePurchase` as today; guard empty
  `productDetails` before `.first`. Keep tips/blacksmith paths untouched.
- Cold-start: one guarded `restorePurchases()` on first store init (flag
  in settings box so it fires once per install), emitting restored events
  the silent path handles.
- `data_management.dart`: `_deleteAll` (~lines 28-58) must **preserve**
  `BoughtPro` alongside `BoughtBlacksmith` (it currently re-sets only
  blacksmith after clearing the Settings box); new keys carry no
  `'dont-show'` prefix so category clears are unaffected.
- Tests in **`test/pro/`** (no purchase-test precedent exists — new home):
  wrap store calls in a thin injectable `ProPurchaseService`; for
  full-stack seams the package's intended fake is
  `InAppPurchasePlatform.instance` (token-verified static setter). Cover:
  entitlement flag → isPro, debug override only in debug, silent vs
  explicit restore (dialog only on explicit), purchase/restored event
  handling, products-missing graceful state, `_deleteAll` preservation.
- Commit: `feat(pro): entitlement store, product ids, purchase wiring`.

### Task 2 — paywall experience
- The full-screen Pro view per UX section (hero, benefits browser, pricing
  from `ProStore.products` with placeholder fallback, buy/restore,
  success confetti, legal link-outs). Phone + tablet layouts per
  design-system responsive rules.
- Widget tests: placeholder state (no products), loaded pricing state
  (fake ProductDetails), buy tap → store called, restore tap, success
  state. Bounded pumps, no real I/O in fake-async.
- Commit: `feat(pro): paywall experience — benefits browser, pricing, restore`.

### Task 3 — gating wiring
- **Rebuild mechanism (decided): `Observer` over `ProStore.isPro`** at each
  gate site — do NOT extend the Hive `rebuildKeys` (the entitlement read
  combines box flag + debug override, which rebuildKeys can't express).
- Chat-bar engine switch (`chat_engine_switch.dart:37-58`): lock badge on
  the Native segment when not Pro; tap intercepted in `onValueChanged` →
  paywall, box put skipped (groupValue stays webView). Update the widget's
  doc comment. Pro users' behavior byte-identical.
- `stream_chat.dart`: single entitlement guard at the top of the
  `if (nativeEngine)` block (before the platform dispatch, ~line 291) →
  not-Pro renders the upsell pane ("Explore Pro" → paywall route) instead
  of all login/setup CTAs; Pro → current behavior untouched.
- Username-bar native cluster (`chat_username_bar.dart:147-148` + account
  controls/options sheets): hidden when not Pro (legacy users with
  persisted `SelectedChatEngine=native` otherwise get dead-end login
  pills). No grandfathering migration — the pane upsell + hidden cluster
  IS the not-Pro native-mode experience.
- Settings entry: "OBS Blade Pro" `BlockEntry` in the Support-adjacent
  block (`settings.dart:326-362` precedent, `navigateToResult` status
  text) — not-Pro → paywall; Pro → thank-you state + manage-subscription
  link-out. The settings list's `HiveBuilder` (no rebuildKeys) rebuilds on
  any settings-box change — `BoughtPro` status text needs no extra wiring.
- **Whole-`test/chat/` impact pass** (not just the named files): every
  native-mode test needs entitlement seeded — preferred: put `BoughtPro`
  in the settings box in `setUp` (exercises the real read; GetIt ProStore
  fake only where the store itself is under test). Known breakers:
  `chat_engine_switch_test.dart:68-104`, `twitch_chat_integration_test.dart`
  (all native-mode cases, lines 90-396), `native_youtube_chat_view_test.dart`,
  `youtube_setup_sheet_test.dart`, `native_chat_window_test.dart`,
  `native_chat_options_sheet_test.dart` — sweep the directory for more.
  Update, don't weaken, asserts.
- Commit: `feat(pro): gate native chat behind entitlement + entry points`.

### Task 4 — wrap-up
- Full gate once + analyze; changelog entry; AGENTS.md update (Pro gate
  paragraph + store wiring note: "add products in App Store Connect /
  Play Console with these ids, no app release logic changes needed");
  handoff reset. foss-strip note in changelog.
- Commit: `docs: pro subscription wave — changelog, handoff, agents note`.

## Explicitly out of scope
Store console product creation (maintainer, later), server-side receipt
validation / RevenueCat (backend wave), actual pricing numbers in UI copy
(rendered from store products when they exist), Studio/Team tier, health
alerts, grandfathering migration logic (no existing paid entitlement
overlaps native chat), lapsed-subscription enforcement (documented
limitation above).
