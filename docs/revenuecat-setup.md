# RevenueCat wiring — reference

**Pro is live since 2026-09:** products created + approved on both stores
(ASC approved with 4.0, Play ACTIVE), the public SDK keys are pasted in
`lib/utils/revenuecat_config.dart`, and per-region pricing was re-applied to
the live stores 2026-10. The app runs the RevenueCat path
(`purchases_flutter`, entitlement `pro`); the legacy direct-IAP path remains
as the key-less fallback (foss strip, dev platforms). This doc is now
reference — what's wired, what to dogfood, and the gotchas.

**Re-provisioning / price refreshes:** `tool/provisioning/` is idempotent —
creds-by-path setup, the RC account/store-connection walkthrough, product
creation (exact ids from `lib/utils/pro_ids.dart`; Play subscription `pro` +
base plans `pro-yearly`/`pro-monthly` + one-time `pro_lifetime`, with the
RC package mapping), and the pricing-table workflow all live in
`tool/provisioning/README.md`.

## Pricing

**$4.99/mo, $49.99/yr, $99.99 lifetime** — the defaults in
`tool/provisioning`.
Per-region pricing is pinned everywhere from one reviewed table
(`tool/provisioning/lib/src/pricing_targets.dart`, re-applied to the live
stores 2026-10): anchors USD/EUR/GBP at the USD nominal, every other
currency at Google's `convertRegionPrices` values (FX-current, tax-aware),
CNY at Apple's China pricing, CHF split CH/LI; ASC 175/175 territories
snapped to the nearest price point, Play ~174 regions exact. The iOS
lifetime IAP follows Apple's auto-equalized schedule instead (maintained
FX-current by Apple). Apple's own equalized tier matrix was dropped after
a 2026-10 audit found >20% deviations in ~30 currencies in both
directions (TRY monthly came through at ~€0.80). Refresh cadence +
workflow: `tool/provisioning/README.md` § Pricing table. Strategy
rationale: `docs/private/monetization-strategy.md`.

## 1. Entitlement + offering (dashboard)

- Create **entitlement `pro`** — the identifier must equal
  `kProEntitlementId` (`lib/utils/revenuecat_config.dart`). Attach all
  three products.
- Create the default **Offering** with three packages pointing at those
  products. The paywall matches packages by `storeProduct.identifier`
  against the three ids and renders yearly as the hero.
- **Legacy products (important):** the real legacy product is
  **blacksmith** (one-time IAP, unlocked custom themes) — there are NO
  pre-RC `pro_lifetime` buyers to migrate (the pro products were created
  store-side on 2026-09-07 and the paywall never shipped with working
  direct IAP). Blacksmith is intentionally NOT migrated into the `pro`
  entitlement: it is no longer sold, and legacy buyers keep their themes
  via the kept direct-IAP restore path (the paywall's Restore purchases
  also fires `InAppPurchase.restorePurchases()` so blacksmith `restored`
  events still reach `PurchaseBase`). Attaching `pro_lifetime` to the
  `pro` entitlement is still required — for all FUTURE lifetime buyers.
  Double-check this linkage if the products are ever re-created.

## 2. API keys → app — done

The **public SDK keys** (RevenueCat dashboard → Apps → API keys; the
"apple_" / "goog_" public app keys, NOT secret keys) are pasted in
`lib/utils/revenuecat_config.dart`. Public keys are safe to commit (they
identify the project, purchases are validated server-side). macOS uses the
Apple key too.

## 3. Verify

1. `flutter test test/pro/` — the backend-selection tests now pin the
   real-keys default (RevenueCat on iOS/Android/macOS, legacy on
   key-less platforms like desktop/web — the foss strip's empty-keys
   state).
2. Sandbox dogfood (physical device, sandbox tester / license tester):
   - paywall now shows live prices (placeholder state replaced),
   - buy `pro_yearly` → confetti + entitlement → native chat unlocks
     **live** (gate sites are Observers),
   - kill + reinstall → cold-start entitlement fetch restores Pro,
   - Restore purchases button → restored dialog,
   - let a sandbox subscription expire (accelerated) → entitlement
     revokes (the lapsed-subscription fix direct IAP couldn't do).
3. The debug override (long-press paywall hero) keeps working regardless
   of backend state.

## Notes / gotchas

- **ASC review screenshots (IAP submission):** each product needs a review
  screenshot that (a) matches a marketing screenshot size *the uploaded
  app binary supports* and (b) has no alpha channel. A 6.3" simulator shot
  (1206×2622) gets "dimensions are wrong" — use 1242×2688 (6.5"),
  flattened. The shot itself is easy: temporarily re-attach
  `ios/obs_blade_storekit.storekit` to the Runner scheme (Run action), run
  on any iPhone sim — the paywall renders real names/prices without
  sandbox — and screenshot the pricing section, then detach it again.
  One image for all three products is fine; review-only, never public.
  The scheme ships WITHOUT the config attached so dogfood runs hit the
  real Apple sandbox.
- **foss branch:** strip `purchases_flutter` alongside the existing IAP
  strip — all RC code is additive; with empty keys the app never touches
  the SDK.
- Tips stay unchanged on direct `in_app_purchase` (`PurchaseBase`).
  Blacksmith is no longer sold — restore-only legacy on the same direct
  IAP stream (the paywall's Restore purchases fires the plugin restore
  alongside RC's). Only the `pro_*` ids moved to RC.
- If `Purchases.configure` fails at cold start (offline), it self-heals
  on next `init()`/launch; a CustomerInfo event between configure and
  listener attach is dropped (broadcast) — the initial fetch covers it.
- Web/desktop dev platforms map to no key → legacy path → graceful
  placeholder. RC has no web support; fine, those aren't store targets.
