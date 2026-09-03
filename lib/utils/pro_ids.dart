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
