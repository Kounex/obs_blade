import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/pro_ids.dart';
import 'package:obs_blade/utils/pro_plan.dart';

void main() {
  group('canonicalProProductId', () {
    test('App Store ids are the plan ids', () {
      expect(canonicalProProductId('pro_monthly'), kProMonthlyId);
      expect(canonicalProProductId('pro_yearly'), kProYearlyId);
      expect(canonicalProProductId('pro_lifetime'), kProLifetimeId);
    });

    test('Play subscriptions map by base plan', () {
      expect(canonicalProProductId('pro:pro-monthly'), kProMonthlyId);
      expect(canonicalProProductId('pro:pro-yearly'), kProYearlyId);
      expect(
        canonicalProProductId('pro', planIdentifier: 'pro-yearly'),
        kProYearlyId,
      );
    });

    test('anything else is not a Pro product', () {
      expect(canonicalProProductId('blacksmith'), isNull);
      expect(canonicalProProductId('tip_1'), isNull);
      expect(canonicalProProductId('pro'), isNull);
      expect(canonicalProProductId('pro:pro-weekly'), isNull);
      expect(canonicalProProductId('other:pro-yearly'), isNull);
    });
  });

  group('proPlanFrom', () {
    ProPlanState plan(
      List<ProSubscriptionRecord> subs, {
      bool lifetime = false,
    }) => proPlanFrom(activeSubscriptions: subs, ownsLifetime: lifetime);

    test('monthly subscriber can switch to yearly or lifetime', () {
      final p = plan([(storeId: 'pro_monthly', willRenew: true)]);
      expect(p.currentPlan, kProMonthlyId);
      expect(p.upgrades, [kProYearlyId, kProLifetimeId]);
      expect(p.renewingSubscriptionStoreId, 'pro_monthly');
      expect(p.subscriptionToCancel, isFalse);
    });

    test('yearly subscriber (Play ids) can only switch to lifetime', () {
      final p = plan([(storeId: 'pro:pro-yearly', willRenew: true)]);
      expect(p.currentPlan, kProYearlyId);
      expect(p.upgrades, [kProLifetimeId]);
      expect(p.renewingSubscriptionStoreId, 'pro:pro-yearly');
    });

    test('lifetime plus a renewing subscription asks to cancel it', () {
      final p = plan([
        (storeId: 'pro_monthly', willRenew: true),
      ], lifetime: true);
      expect(p.currentPlan, kProLifetimeId);
      expect(p.upgrades, isEmpty);
      expect(p.subscriptionToCancel, isTrue);
      expect(p.renewingSubscription, kProMonthlyId);
    });

    test('lifetime with the subscription already cancelled is settled', () {
      final p = plan([
        (storeId: 'pro_monthly', willRenew: false),
      ], lifetime: true);
      expect(p.subscriptionToCancel, isFalse);
      expect(p.upgrades, isEmpty);
    });

    test('a cancelled but still active subscription keeps its tier', () {
      final p = plan([(storeId: 'pro_monthly', willRenew: false)]);
      expect(p.currentPlan, kProMonthlyId);
      expect(p.renewingSubscription, isNull);
      expect(p.upgrades, [kProYearlyId, kProLifetimeId]);
    });

    test('no Pro purchase, or products this app does not sell', () {
      expect(plan([]), ProPlanState.none);
      expect(plan([(storeId: 'tip_1', willRenew: true)]), ProPlanState.none);
      expect(ProPlanState.none.upgrades, isEmpty);
    });
  });
}
