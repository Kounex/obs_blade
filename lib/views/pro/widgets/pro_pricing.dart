import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../shared/general/base/card.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/pro_ids.dart';
import '../../../utils/pro_product.dart';
import '../../../utils/styling_helper.dart';
import '../../settings/widgets/support_dialog/support_skeleton.dart';

/// Pricing section of the paywall: ONE card with the three plans as
/// selectable rows and a single CTA (was three cards with a button each).
/// Yearly is preselected. States (Observer over [ProStore]):
/// - loading: skeleton rows while the store answers the FIRST product
///   query ([ProStore.productsLoaded]) - a restore also flips `pending`,
///   but keeps the current card instead of falling back to skeletons
/// - store unreachable / products missing (the expected state until the
///   products exist store-side): "price shown at purchase" rows, the CTA
///   explains instead of charging
/// - priced: live [ProProduct]s
///
/// Same composition on tablet - the card sits in the 640 content column.
class ProPricing extends StatefulWidget {
  final ProStore store;

  /// First stagger index for the entrance - the paywall sections above
  /// own the lower indexes
  final int entranceIndexBase;

  const ProPricing({
    super.key,
    required this.store,
    this.entranceIndexBase = 0,
  });

  static const List<ProOffer> offers = [
    ProOffer(
      productId: kProYearlyId,
      title: 'Yearly',
      cadence: 'per year',
      badge: 'BEST VALUE',
    ),
    ProOffer(productId: kProMonthlyId, title: 'Monthly', cadence: 'per month'),
    ProOffer(
      productId: kProLifetimeId,
      title: 'Lifetime',
      cadence: 'once - yours forever',
      badge: 'ONE-TIME',
    ),
  ];

  @override
  State<ProPricing> createState() => _ProPricingState();
}

class _ProPricingState extends State<ProPricing> {
  String _selectedId = kProYearlyId;

  ProOffer get _selected =>
      ProPricing.offers.firstWhere((offer) => offer.productId == _selectedId);

  ProProduct? _productFor(String productId) {
    for (final ProProduct product in this.widget.store.products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  void _buy(BuildContext context, ProProduct? product) {
    if (product == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Pro isn\'t live in the store yet - once it launches, the '
              'price shows right here and nothing is charged before you '
              'confirm.',
            ),
          ),
        );
      return;
    }
    this.widget.store.buy(product);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final ProStore store = this.widget.store;

        /// Skeleton only for the initial product load - a restore flips
        /// `pending` too, but the current card stays put while it runs
        if (store.pending && store.products.isEmpty && !store.productsLoaded) {
          return const SupportSkeleton(rows: 3);
        }

        final ProOffer selected = this._selected;
        final ProProduct? selectedProduct = this._productFor(
          selected.productId,
        );

        return StaggeredEntrance(
          index: this.widget.entranceIndexBase,
          scaleFrom: 0.985,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (store.lastError == 'store-unavailable')
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Can\'t reach the store right now - pricing appears '
                    'once your connection is back.',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(
                        context,
                      ).extension<AppTextColors>()!.textSecondary,
                    ),
                  ),
                ),
              BaseCard(
                constrained: false,
                centerChild: false,
                topPadding: 0.0,
                rightPadding: 0.0,
                bottomPadding: 0.0,
                leftPadding: 0.0,
                paddingChild: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    for (final (int i, ProOffer offer)
                        in ProPricing.offers.indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      _PlanRow(
                        offer: offer,
                        product: this._productFor(offer.productId),
                        selected: offer.productId == this._selectedId,
                        onTap: () =>
                            setState(() => this._selectedId = offer.productId),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    /// The paywall's one accent moment (token-delta §5)
                    SizedBox(
                      width: double.infinity,
                      child: Opacity(
                        opacity: selectedProduct == null ? 0.55 : 1.0,
                        child: BaseButton(
                          text: selectedProduct == null
                              ? 'Not live yet'
                              : 'Get Pro ${selected.title}',
                          onPressed: store.pending
                              ? null
                              : () => this._buy(context, selectedProduct),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      selected.productId == kProLifetimeId
                          ? 'One payment, no subscription.'
                          : 'Cancel anytime in your store settings.',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(
                          context,
                        ).extension<AppTextColors>()!.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProOffer {
  final String productId;
  final String title;
  final String cadence;
  final String? badge;

  const ProOffer({
    required this.productId,
    required this.title,
    required this.cadence,
    this.badge,
  });
}

/// One selectable plan: radio mark, title (+ badge) over cadence, price.
/// Selection = accent ring + radio fill on a faint accent wash; the
/// unselected rows stay neutral.
class _PlanRow extends StatelessWidget {
  final ProOffer offer;

  /// Null while the product doesn't exist store-side (placeholder state)
  final ProProduct? product;

  final bool selected;
  final VoidCallback onTap;

  const _PlanRow({
    required this.offer,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    final Color neutral = Theme.of(context).cardColor.computeLuminance() <= 0.2
        ? Colors.white
        : Colors.black;

    return Semantics(
      button: true,
      selected: this.selected,
      label: '${this.offer.title} plan',
      child: Pressable(
        onTap: this.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          constraints: const BoxConstraints(minHeight: 64.0),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            /// Nested-tint rule (token-delta §2.3): a 6% wash keeps the
            /// accent-text badge and secondary copy on it above 4.3:1
            color: this.selected
                ? accent.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: this.selected ? accent : neutral.withValues(alpha: 0.12),
              width: this.selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              _RadioMark(selected: this.selected, color: accent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          this.offer.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (this.offer.badge != null)
                          Text(
                            this.offer.badge!,
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(
                                  /// Neutral text levels, not the accent:
                                  /// accent-as-text drops under 3:1 on the
                                  /// selected row's wash in several
                                  /// built-in themes (Pure Indigo 2.4:1) -
                                  /// the ring + radio carry the selection
                                  color: this.selected
                                      ? textColors.textPrimary
                                      : textColors.textSecondary,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      this.product == null
                          ? 'Price shown at purchase'
                          : this.offer.cadence,
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: textColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (this.product != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  this.product!.priceString,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  final bool selected;
  final Color color;

  const _RadioMark({required this.selected, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      width: 22.0,
      height: 22.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: this.selected ? this.color : Colors.transparent,
        border: Border.all(
          color: this.selected
              ? this.color
              : Theme.of(context).extension<AppTextColors>()!.textTertiary,
          width: 1.5,
        ),
      ),
      child: this.selected
          ? Icon(
              CupertinoIcons.checkmark_alt,
              size: 14.0,
              color: StylingHelper.surroundingAwareAccent(
                surroundingColor: this.color,
              ),
            )
          : null,
    );
  }
}
