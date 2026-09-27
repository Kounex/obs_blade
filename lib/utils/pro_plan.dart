import 'pro_ids.dart';

/// Which Pro plan the user holds and what still bills them - drives the
/// tiered plan switch on the Pro page (monthly -> yearly or lifetime,
/// yearly -> lifetime) and the "cancel your subscription" reminder once
/// lifetime is bought while a subscription still renews.
class ProPlanState {
  /// `pro_monthly` / `pro_yearly` / `pro_lifetime`, or null when there is
  /// no Pro plan (or one this app doesn't sell, e.g. a promotional grant).
  final String? currentPlan;

  /// A Pro subscription that is set to renew, as a plan id.
  final String? renewingSubscription;

  /// That subscription's store identifier - what a Play product change
  /// has to name as the product being replaced.
  final String? renewingSubscriptionStoreId;

  const ProPlanState({
    this.currentPlan,
    this.renewingSubscription,
    this.renewingSubscriptionStoreId,
  });

  static const ProPlanState none = ProPlanState();

  /// Plans this user can switch to from the Pro page.
  List<String> get upgrades => switch (this.currentPlan) {
    kProMonthlyId => const [kProYearlyId, kProLifetimeId],
    kProYearlyId => const [kProLifetimeId],
    _ => const [],
  };

  /// Lifetime is owned but a subscription keeps renewing - the stores
  /// never cancel it on their own, the user has to.
  bool get subscriptionToCancel =>
      this.currentPlan == kProLifetimeId && this.renewingSubscription != null;

  @override
  bool operator ==(Object other) =>
      other is ProPlanState &&
      other.currentPlan == this.currentPlan &&
      other.renewingSubscription == this.renewingSubscription &&
      other.renewingSubscriptionStoreId == this.renewingSubscriptionStoreId;

  @override
  int get hashCode => Object.hash(
    this.currentPlan,
    this.renewingSubscription,
    this.renewingSubscriptionStoreId,
  );

  @override
  String toString() =>
      'ProPlanState($currentPlan, renewing: $renewingSubscription)';
}

/// One active subscription as the store reports it.
typedef ProSubscriptionRecord = ({String storeId, bool willRenew});

/// Derives the plan from what the purchase backend knows: the active
/// subscriptions (store ids, whether each renews) and whether lifetime is
/// owned. Lifetime wins as the current plan; among subscriptions, yearly
/// before monthly.
ProPlanState proPlanFrom({
  required Iterable<ProSubscriptionRecord> activeSubscriptions,
  required bool ownsLifetime,
}) {
  String? yearly, monthly;
  ProSubscriptionRecord? renewing;
  for (final ProSubscriptionRecord sub in activeSubscriptions) {
    final String? plan = canonicalProProductId(sub.storeId);
    if (plan == kProYearlyId) yearly = plan;
    if (plan == kProMonthlyId) monthly = plan;
    if (plan != null && sub.willRenew) {
      /// Both renewing would be a store oddity - prefer the yearly one
      if (renewing == null || plan == kProYearlyId) renewing = sub;
    }
  }
  return ProPlanState(
    currentPlan: ownsLifetime ? kProLifetimeId : (yearly ?? monthly),
    renewingSubscription: renewing == null
        ? null
        : canonicalProProductId(renewing.storeId),
    renewingSubscriptionStoreId: renewing?.storeId,
  );
}
