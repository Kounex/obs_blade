import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/pro_ids.dart';
import '../../../utils/pro_product.dart';
import '../../../utils/styling_helper.dart';
import '../../settings/widgets/support_dialog/support_skeleton.dart';
import 'pro_palette.dart';

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
      icon: CupertinoIcons.star_fill,
    ),
    ProOffer(
      productId: kProMonthlyId,
      title: 'Monthly',
      cadence: 'per month',
      icon: CupertinoIcons.calendar,
    ),
    ProOffer(
      productId: kProLifetimeId,
      title: 'Lifetime',
      cadence: 'once - yours forever',
      badge: 'ONE-TIME',
      icon: CupertinoIcons.infinite,
      color: ProPalette.gold,
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

        final Color accent = Theme.of(
          context,
        ).buttonTheme.colorScheme!.secondary;
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
                paintBorder: true,
                borderColor: accent.withValues(alpha: 0.35),
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
                    _ProCta(
                      text: selectedProduct == null
                          ? 'Not live yet'
                          : 'Get Pro ${selected.title}',
                      placeholder: selectedProduct == null,
                      onPressed: store.pending
                          ? null
                          : () => this._buy(context, selectedProduct),
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
  final IconData icon;

  /// Identity hue of the row - null uses the theme accent
  final Color? color;

  const ProOffer({
    required this.productId,
    required this.title,
    required this.cadence,
    required this.icon,
    this.badge,
    this.color,
  });
}

/// One selectable plan: radio mark, icon, title + cadence, price. The
/// selected row lights up in its identity hue.
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
    final Color hue =
        this.offer.color ??
        Theme.of(context).buttonTheme.colorScheme!.secondary;
    final Color ink = ProPalette.ink(context, hue);
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    final bool dark = ProPalette.darkSurface(context);
    final Color neutral = (dark ? Colors.white : Colors.black);

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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: this.selected
                ? hue.withValues(alpha: 0.14)
                : neutral.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: this.selected
                  ? hue.withValues(alpha: 0.9)
                  : neutral.withValues(alpha: 0.08),
              width: this.selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              _RadioMark(selected: this.selected, color: hue),
              const SizedBox(width: AppSpacing.md),
              Icon(
                this.offer.icon,
                size: 18.0,
                color: this.selected ? ink : textColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
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
                          _Badge(text: this.offer.badge!, color: hue),
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
              : Theme.of(context).extension<AppTextColors>()!.textOrnament,
          width: 1.5,
        ),
      ),
      child: this.selected
          ? Icon(
              CupertinoIcons.checkmark_alt,
              size: 14.0,
              color: this.color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
            )
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2.0,
      ),
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.18),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        this.text,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: ProPalette.ink(context, this.color),
        ),
      ),
    );
  }
}

/// The paywall's one filled CTA: accent gradient with a soft glow
class _ProCta extends StatelessWidget {
  final String text;
  final bool placeholder;
  final VoidCallback? onPressed;

  const _ProCta({
    required this.text,
    required this.placeholder,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final Color deep = Color.lerp(accent, Colors.black, 0.3)!;

    /// Gradient pill + glow painted by the button's own container, the
    /// label pressed through [Pressable] like every other button (a
    /// transparent ElevatedButton over a gradient box leaves the box
    /// peeking out under Material's tap-target padding)
    return Semantics(
      button: true,
      enabled: this.onPressed != null,
      child: Pressable(
        onTap: this.onPressed,
        child: Opacity(
          opacity: this.placeholder || this.onPressed == null ? 0.55 : 1.0,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 52.0),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              gradient: LinearGradient(colors: [accent, deep]),
              boxShadow: this.placeholder
                  ? null
                  : [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 18.0,
                        offset: const Offset(0.0, 4.0),
                      ),
                    ],
            ),

            /// Filled-CTA label contract (token-delta §2.4): 17/700
            child: Text(
              this.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
                color: StylingHelper.surroundingAwareAccent(
                  surroundingColor: accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
