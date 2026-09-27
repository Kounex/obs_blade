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

/// Play side of the subscription pair: one subscription product with a
/// base plan per cadence. RevenueCat reports such products as
/// `<subscription>:<base plan>` (e.g. `pro:pro-yearly`).
const String kPlayProSubscriptionId = 'pro';
const Map<String, String> _kPlayProBasePlans = {
  'pro-yearly': kProYearlyId,
  'pro-monthly': kProMonthlyId,
};

/// The app's plan id (`pro_yearly` / `pro_monthly` / `pro_lifetime`) for a
/// store product identifier, or null when it isn't a Pro product. App
/// Store ids already are the plan ids; Play subscriptions come as
/// `pro:pro-yearly`, or as `pro` with the base plan in [planIdentifier].
String? canonicalProProductId(
  String storeIdentifier, {
  String? planIdentifier,
}) {
  if (isProProductId(storeIdentifier)) return storeIdentifier;
  final List<String> parts = storeIdentifier.split(':');
  if (parts.first != kPlayProSubscriptionId) return null;
  return _kPlayProBasePlans[parts.length > 1 ? parts[1] : planIdentifier];
}

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
