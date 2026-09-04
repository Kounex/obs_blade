import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/responsive_widget_wrapper.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/pro_ids.dart';
import '../../settings/widgets/support_dialog/support_skeleton.dart';

/// Pricing section of the paywall. States (Observer over [ProStore]):
/// - loading: skeleton rows while the store answers
/// - store unreachable / products missing (the expected state until the
///   products exist store-side): placeholder cards — "price shown at
///   purchase" copy, buy tap explains instead of charging
/// - priced: live [ProductDetails], yearly framed as the best value
class ProPricing extends StatelessWidget {
  final ProStore store;

  const ProPricing({super.key, required this.store});

  static const List<_ProOffer> _offers = [
    _ProOffer(
      productId: kProYearlyId,
      title: 'Yearly',
      cadence: 'per year',
      badge: 'BEST VALUE',
      isHero: true,
    ),
    _ProOffer(
      productId: kProMonthlyId,
      title: 'Monthly',
      cadence: 'per month',
    ),
    _ProOffer(
      productId: kProLifetimeId,
      title: 'Lifetime',
      cadence: 'once — yours forever',
      badge: 'ONE-TIME',
    ),
  ];

  void _buy(BuildContext context, _ProOffer offer, ProductDetails? product) {
    if (product == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Pro isn\'t live in the store yet — once it launches, the '
              'price shows right here and nothing is charged before you '
              'confirm.',
            ),
          ),
        );
      return;
    }
    this.store.buy(product);
  }

  ProductDetails? _productFor(String productId) {
    for (final ProductDetails product in this.store.products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (this.store.pending && this.store.products.isEmpty) {
          return const SupportSkeleton(rows: 3);
        }

        final List<Widget> cards = [
          for (final _ProOffer offer in _offers)
            _ProPriceCard(
              offer: offer,
              product: this._productFor(offer.productId),
              pending: this.store.pending,
              onBuy: (product) => this._buy(context, offer, product),
            ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (this.store.lastError == 'store-unavailable')
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Can\'t reach the store right now — pricing appears once '
                  'your connection is back.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ResponsiveWidgetWrapper(
              mobileWidget: Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    cards[i],
                  ],
                ],
              ),
              tabletWidget: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProOffer {
  final String productId;
  final String title;
  final String cadence;
  final String? badge;
  final bool isHero;

  const _ProOffer({
    required this.productId,
    required this.title,
    required this.cadence,
    this.badge,
    this.isHero = false,
  });
}

class _ProPriceCard extends StatelessWidget {
  final _ProOffer offer;

  /// Null while the product doesn't exist store-side (placeholder state)
  final ProductDetails? product;

  /// A store call is in flight - buys disabled to prevent double taps
  final bool pending;

  final void Function(ProductDetails? product) onBuy;

  const _ProPriceCard({
    required this.offer,
    required this.product,
    required this.pending,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final bool placeholder = this.product == null;

    return BaseCard(
      constrained: false,
      centerChild: false,
      topPadding: 0.0,
      rightPadding: 0.0,
      bottomPadding: 0.0,
      leftPadding: 0.0,
      paintBorder: this.offer.isHero,
      borderColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  this.offer.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (this.offer.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    this.offer.badge!,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            this.product?.price ?? 'Price shown at purchase',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            this.offer.cadence,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: Opacity(
              opacity: placeholder ? 0.55 : 1.0,
              child: BaseButton(
                text: placeholder ? 'Not live yet' : 'Choose ${this.offer.title}',
                secondary: !this.offer.isHero,
                onPressed:
                    this.pending ? null : () => this.onBuy(this.product),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
