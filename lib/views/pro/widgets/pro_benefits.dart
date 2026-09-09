import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/responsive_widget_wrapper.dart';
import '../../settings/widgets/decorative_icon_tile.dart';

/// One browsable Pro benefit. Copy rule (monetization strategy):
/// honest, no dates promised for unreleased features.
class ProBenefit {
  final IconData icon;
  final String title;
  final String body;

  const ProBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });
}

const List<ProBenefit> kProBenefits = [
  ProBenefit(
    icon: CupertinoIcons.chat_bubble_text_fill,
    title: 'Native Twitch Chat',
    body:
        'Read and write chat right from your phone — fast, smooth and without a browser embed.',
  ),
  ProBenefit(
    icon: CupertinoIcons.play_rectangle_fill,
    title: 'Native YouTube Chat',
    body:
        'A real YouTube chat experience, including Super Chat rendering, straight in your dashboard.',
  ),
  ProBenefit(
    icon: CupertinoIcons.shield_fill,
    title: 'Phone-Native Moderation',
    body:
        'Delete, timeout or ban with a tap — mod tools designed for one hand, not a desk.',
  ),
  ProBenefit(
    icon: CupertinoIcons.sparkles,
    title: 'What\'s Next',
    body:
        'Pro keeps growing — think stream health alerts and deeper platform tools. No dates promised, but the bench is full.',
  ),
];

/// Browsable benefits: a swipeable card carousel with page dots on phone,
/// a 2x2 grid on tablet (design system § Responsive layouts).
class ProBenefitsBrowser extends StatefulWidget {
  const ProBenefitsBrowser({super.key});

  @override
  State<ProBenefitsBrowser> createState() => _ProBenefitsBrowserState();
}

class _ProBenefitsBrowserState extends State<ProBenefitsBrowser> {
  final PageController _pageController = PageController(
    viewportFraction: 0.88,
  );

  @override
  void dispose() {
    this._pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// The carousel is fixed-height (PageView needs a bound), so grow it
    /// with the text scale - clamped, so accessibility sizes enlarge the
    /// cards without the carousel eating the whole paywall
    final double textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.4);

    return ResponsiveWidgetWrapper(
      mobileWidget: Column(
        children: [
          SizedBox(
            height: 216.0 * textScale,
            child: PageView.builder(
              controller: this._pageController,
              itemCount: kProBenefits.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: ProBenefitCard(benefit: kProBenefits[index]),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SmoothPageIndicator(
            controller: this._pageController,
            count: kProBenefits.length,
            effect: WormEffect(
              dotHeight: 8.0,
              dotWidth: 8.0,
              spacing: AppSpacing.sm,
              dotColor:
                  Theme.of(context).dividerColor.withValues(alpha: 0.35),
              activeDotColor:
                  Theme.of(context).buttonTheme.colorScheme!.secondary,
            ),
          ),
        ],
      ),
      tabletWidget: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ProBenefitCard(benefit: kProBenefits[0])),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: ProBenefitCard(benefit: kProBenefits[1])),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: ProBenefitCard(benefit: kProBenefits[2])),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: ProBenefitCard(benefit: kProBenefits[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class ProBenefitCard extends StatelessWidget {
  final ProBenefit benefit;

  const ProBenefitCard({super.key, required this.benefit});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      constrained: false,
      centerChild: false,
      topPadding: 0.0,
      rightPadding: 0.0,
      bottomPadding: 0.0,
      leftPadding: 0.0,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Decorative tiles are neutral (token-delta rule 5) - the
            /// paywall's one accent moment is the yearly CTA
            DecorativeIconTile(
              icon: this.benefit.icon,
              size: 40.0,
              iconSize: 22.0,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              this.benefit.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              this.benefit.body,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context)
                        .extension<AppTextColors>()!
                        .textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
