import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../shared/general/base/card.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/pro_ids.dart';
import '../../../utils/pro_product.dart';
import 'pro_pricing.dart';

/// Store the purchase runs through - named in the plan-switch notes.
String get _storeName =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

String _planName(String planId) => ProPricing.offers
    .firstWhere((offer) => offer.productId == planId)
    .title
    .toLowerCase();

/// Tiered plan switch on the Pro page: monthly subscribers can move to
/// yearly or lifetime, yearly subscribers to lifetime, lifetime owners
/// see nothing. Built from [ProStore.plan] and the loaded products.
class ProPlanSwitch extends StatelessWidget {
  final ProStore store;

  const ProPlanSwitch({super.key, required this.store});

  /// What the switch does, per platform - the stores handle them
  /// differently (see [ProStore.buy]).
  static String note(String target, String current) {
    if (target == kProLifetimeId) {
      return 'One payment, Pro for good. Your ${_planName(current)} '
          'subscription keeps renewing until you cancel it - do that in '
          'your $_storeName subscriptions after buying.';
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'Replaces your ${_planName(current)} plan from your next renewal '
              'date.'
        : 'Replaces your ${_planName(current)} plan right away - the unused '
              'part of it is credited.';
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final String? current = this.store.plan.currentPlan;
        final List<String> upgrades = this.store.plan.upgrades;
        if (current == null || upgrades.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('SWITCH PLAN', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            for (final String target in upgrades) ...[
              _SwitchCard(
                store: this.store,
                offer: ProPricing.offers.firstWhere(
                  (offer) => offer.productId == target,
                ),
                note: note(target, current),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final ProStore store;
  final ProOffer offer;
  final String note;

  const _SwitchCard({
    required this.store,
    required this.offer,
    required this.note,
  });

  ProProduct? get _product {
    for (final ProProduct product in this.store.products) {
      if (product.id == this.offer.productId) return product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    return Observer(
      builder: (context) {
        final ProProduct? product = this._product;
        return BaseCard(
          key: Key('pro-switch-${this.offer.productId}'),
          constrained: false,
          centerChild: false,
          topPadding: 0.0,
          rightPadding: 0.0,
          bottomPadding: 0.0,
          leftPadding: 0.0,
          paddingChild: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      this.offer.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (product != null)
                    Text(
                      '${product.priceString} ${this.offer.cadence}',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: textColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                this.note,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: textColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: BaseButton(
                  text: product == null
                      ? 'Not available right now'
                      : this.offer.productId == kProLifetimeId
                      ? 'Get Lifetime'
                      : 'Switch to ${this.offer.title}',
                  secondary: true,
                  onPressed: product == null || this.store.pending
                      ? null
                      : () => this.store.buy(product),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Lifetime is owned but a subscription still renews - the stores never
/// cancel it on their own, so say so plainly and link the store's
/// subscription page.
class ProCancelSubscriptionNotice extends StatelessWidget {
  final ProStore store;
  final VoidCallback onOpenSubscriptions;

  const ProCancelSubscriptionNotice({
    super.key,
    required this.store,
    required this.onOpenSubscriptions,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final String? renewing = this.store.plan.renewingSubscription;
        if (!this.store.plan.subscriptionToCancel || renewing == null) {
          return const SizedBox();
        }
        final Color warning = Theme.of(
          context,
        ).extension<AppStatusColors>()!.warning;

        return BaseCard(
          key: const Key('pro-cancel-subscription'),
          constrained: false,
          centerChild: false,
          paintBorder: true,
          borderColor: warning,
          topPadding: 0.0,
          rightPadding: 0.0,
          bottomPadding: 0.0,
          leftPadding: 0.0,
          paddingChild: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancel your ${_planName(renewing)} subscription',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(color: warning),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'You own Lifetime now, but your ${_planName(renewing)} '
                'subscription still renews. Cancel it in your $_storeName '
                'subscriptions so you aren\'t charged again.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: BaseButton(
                  text: 'Open subscriptions',
                  onPressed: this.onOpenSubscriptions,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
