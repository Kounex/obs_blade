/// Platform-neutral view of a Pro store product. Both pro purchase
/// backends (direct `in_app_purchase` and RevenueCat) produce these so
/// the paywall never touches store-specific types.
class ProProduct {
  /// Store product id (`pro_yearly` / `pro_monthly` / `pro_lifetime`).
  final String id;

  final String title;

  /// Localized, formatted price (e.g. `€19.99`) — display only.
  final String priceString;

  /// ISO 8601 subscription period (`P1Y`, `P1M`, …) for subscriptions,
  /// null for the lifetime buy-out. Display metadata only — the paywall
  /// hardcodes its cadence copy, this rides along for future use.
  final String? subscriptionPeriod;

  /// Underlying store object the active backend buys with
  /// (`ProductDetails` for direct IAP, RevenueCat `Package` for RC).
  /// Opaque to the UI — only the backend that produced it casts it back.
  final Object? storeObject;

  const ProProduct({
    required this.id,
    required this.title,
    required this.priceString,
    this.subscriptionPeriod,
    this.storeObject,
  });
}
