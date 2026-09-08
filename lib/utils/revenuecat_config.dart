import 'package:flutter/foundation.dart';

/// RevenueCat entitlement that maps to "Pro" — configure it
/// dashboard-side with `pro_yearly` / `pro_monthly` / `pro_lifetime`
/// attached.
const String kProEntitlementId = 'pro';

/// RevenueCat public SDK keys ("API keys" in the dashboard, one per
/// store). EMPTY = RevenueCat not configured — the app then runs the
/// legacy direct-`in_app_purchase` pro path ([revenueCatConfigured] is
/// false). The real keys are filled in on `master`; the foss strip
/// blanks them again, which keeps the legacy path with no RC SDK
/// contact.
const String kRevenueCatAppleApiKey = 'appl_NZGxSIrVfToCjPdOuPbzVqDizTt';
const String kRevenueCatGoogleApiKey = 'goog_vAmJOhHOtjqXKvfzBrchUfJPEol';

/// The platform's RevenueCat key, or null when there is none for this
/// platform (key empty, or a platform RevenueCat doesn't serve here —
/// desktop/web keep the legacy path where the store is simply
/// unavailable).
String? get revenueCatApiKey {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return kRevenueCatAppleApiKey.isEmpty ? null : kRevenueCatAppleApiKey;
    case TargetPlatform.android:
      return kRevenueCatGoogleApiKey.isEmpty
          ? null
          : kRevenueCatGoogleApiKey;
    default:
      return null;
  }
}

/// Single switch for the dual-path transition: true once the maintainer
/// has dropped the platform key in above. Everything Pro (entitlement
/// source, products, purchase, restore) then rides RevenueCat; the
/// direct-IAP pro path stays as the fallback while unconfigured.
bool get revenueCatConfigured => revenueCatApiKey != null;
