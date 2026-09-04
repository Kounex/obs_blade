# RevenueCat wiring — how to take Pro live

The app side is done (2026-09-04, `feat(pro): revenuecat gateway …`).
Everything below is dashboard/config work — **no app-code changes needed**
except pasting two API keys. When the keys are filled, the app switches
from the legacy direct-IAP path to RevenueCat automatically
(`revenueCatConfigured` in `lib/utils/revenuecat_config.dart`).

## 1. RevenueCat account + project

1. Create a RevenueCat account → new project "OBS Blade".
2. Add two apps: iOS (bundle id from `ios/Runner.xcodeproj`) and Android
   (applicationId from `android/app/build.gradle`).
3. Connect the stores:
   - **App Store:** App Store Connect API key (in-app purchase key) +
     shared secret if prompted; enable App Store Server Notifications V2
     with the RevenueCat URL so renewals/refunds reach RC.
   - **Google Play:** Play service-account JSON + Real-time developer
     notifications topic wired to RC.

## 2. Store products (exact ids — already in `lib/utils/pro_ids.dart`)

| Store product | Type | RC package |
|---|---|---|
| `pro_yearly` | auto-renewable subscription (App Store: subscription group "Pro"; Play: base plan) | attach |
| `pro_monthly` | same subscription group | attach |
| `pro_lifetime` | non-consumable (Play: one-time product) | attach |

Pricing per `docs/private/monetization-strategy.md` (Pro tier:
~$14.99–24.99/yr, lifetime ~$59.99–79.99; monthly at your discretion).

## 3. Entitlement + offering (dashboard)

- Create **entitlement `pro`** — the identifier must equal
  `kProEntitlementId` (`lib/utils/revenuecat_config.dart`). Attach all
  three products.
- Create the default **Offering** with three packages pointing at those
  products. The paywall matches packages by `storeProduct.identifier`
  against the three ids and renders yearly as the hero.
- **Legacy-buyer migration (important):** anyone who bought
  `pro_lifetime` via direct IAP before the RC flip is picked up ONLY if
  `pro_lifetime` is attached to the `pro` entitlement — RC's
  `restorePurchases` syncs the store receipt and grants it. Double-check
  this linkage before shipping the keys, or those buyers strand.

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

- **foss branch:** strip `purchases_flutter` alongside the existing IAP
  strip — all RC code is additive; with empty keys the app never touches
  the SDK.
- Tips + Blacksmith stay on direct `in_app_purchase` (`PurchaseBase`) —
  only the `pro_*` ids moved to RC.
- If `Purchases.configure` fails at cold start (offline), it self-heals
  on next `init()`/launch; a CustomerInfo event between configure and
  listener attach is dropped (broadcast) — the initial fetch covers it.
- Web/desktop dev platforms map to no key → legacy path → graceful
  placeholder. RC has no web support; fine, those aren't store targets.
