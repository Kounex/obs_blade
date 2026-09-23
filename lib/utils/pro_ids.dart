/// Product ids for the "Pro" entitlement (subscription pair + lifetime
/// buy-out). The ids ARE the final strings (we control them store-side)
/// but the store products don't exist yet — every store query with these
/// ids may legitimately return nothing / list them in `notFoundIDs`, so
/// all consumers must degrade gracefully.
const String kProYearlyId = 'pro_yearly';
const String kProMonthlyId = 'pro_monthly';
const String kProLifetimeId = 'pro_lifetime';

const Set<String> kProProductIds = {
  kProYearlyId,
  kProMonthlyId,
  kProLifetimeId,
};

bool isProProductId(String productId) => kProProductIds.contains(productId);

/// Release-build testing escape hatch
/// (`--dart-define=PRO_RELEASE_TEST_UNLOCK=true`): extends the hidden
/// paywall long-press override ([ProStore.debugOverride]) — normally
/// `kDebugMode`-only — to a release build too, so Pro-gated paths can be
/// dogfooded on a release/TestFlight build before the store products are
/// purchasable. Defaults false: a build without the define behaves exactly
/// like today. Never pass this define for a build that reaches real users.
const bool kProReleaseTestUnlock = bool.fromEnvironment(
  'PRO_RELEASE_TEST_UNLOCK',
);
