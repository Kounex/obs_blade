# RevenueCat wiring — how to take Pro live

The app side is done (2026-09-04, `feat(pro): revenuecat gateway …`).
Everything below is dashboard/config work — **no app-code changes needed**
except pasting two API keys. When the keys are filled, the app switches
from the legacy direct-IAP path to RevenueCat automatically
(`revenueCatConfigured` in `lib/utils/revenuecat_config.dart`).

**Scripted path (preferred):** `tool/provisioning/` creates the store
products for you — see its README for creds-by-path setup, then:

```bash
# With creds exported (e.g. from ~/.localrc — collection walkthrough:
# tool/provisioning/CREDENTIALS.md):
dart run tool/provisioning/bin/provision.dart asc-products
dart run tool/provisioning/bin/provision.dart play-products
# …or pass --key-path/--key-id/--issuer-id/--app-id /
# --service-account-json explicitly; flags win over env.
```

Both are idempotent (re-runs are no-ops), create the exact ids from
`lib/utils/pro_ids.dart` (Play uses subscription `pro` + base plans
`pro-yearly`/`pro-monthly` — the RevenueCat package mapping is in the tool
README), and set US base prices. **Console-only remainder:** paid-apps
agreement + tax/banking, and product review submission. The manual
walkthrough below doubles as the verification checklist afterwards.

## 1. RevenueCat account + project

1. Create a RevenueCat account → new project "OBS Blade".
2. Add two apps: iOS (bundle id from `ios/Runner.xcodeproj`) and Android
   (applicationId from `android/app/build.gradle`).
3. Connect the stores:
   - **App Store:** App Store Connect API key (in-app purchase key) +
     App-Specific Shared Secret (optional but recommended — only needed to
     read legacy receipts; there is nothing to migrate, see §3); enable
     App Store Server Notifications V2 with the RevenueCat URL so
     renewals/refunds reach RC.
   - **Google Play:** Play service-account JSON + Real-time developer
     notifications topic wired to RC.

## 2. Store products (exact ids — already in `lib/utils/pro_ids.dart`)

| Store product | Type | RC package |
|---|---|---|
| `pro_yearly` | auto-renewable subscription (App Store: subscription group "Pro"; Play: base plan) | attach |
| `pro_monthly` | same subscription group | attach |
| `pro_lifetime` | non-consumable (Play: one-time product) | attach |

Pricing is locked and already provisioned store-side (2026-09): **$4.99/mo,
$49.99/yr, $99.99 lifetime** — the defaults in `tool/provisioning`.
Per-region pricing is pinned everywhere: ASC 175/175 territories (nominal
or equalized-tier fallback), Play 173/173 regions — default driven by
Apple's equalized tier table per currency for exact cross-store parity
(`play-products --price-source apple`; `--price-source google` keeps
Play's converted table + EUR/GBP/USD nominal parity). Strategy
rationale: `docs/private/monetization-strategy.md`.

## 3. Entitlement + offering (dashboard)

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
  Double-check this linkage before shipping the keys.

## 4. API keys → app

Paste the **public SDK keys** (RevenueCat dashboard → Apps → API keys;
the "apple_" / "goog_" public app keys, NOT secret keys) into
`lib/utils/revenuecat_config.dart`:

```dart
const String kRevenueCatAppleApiKey = 'appl_…';
const String kRevenueCatGoogleApiKey = 'goog_…';
```

Public keys are safe to commit (they identify the project, purchases are
validated server-side). macOS uses the Apple key too.

## 5. Verify

1. `bash flutterw test test/pro/` — note: the "empty keys → legacy
   selection" test is marked with a revisit comment
   (`test/pro/revenuecat_pro_gateway_test.dart`); once keys are real it
   needs a fixture tweak, not a behavior fix.
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
  flattened. The shot itself is easy: run on any iPhone sim (the scheme
  has `ios/obs_blade_storekit.storekit` attached, so the paywall renders
  real names/prices without sandbox) and screenshot the pricing section.
  One image for all three products is fine; review-only, never public.
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
