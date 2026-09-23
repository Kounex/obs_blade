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
    title: 'Native Chat, Every Platform',
    body:
        'Read and write Twitch, Kick and YouTube chat right from your phone - fast and smooth, no browser embed.',
  ),
  ProBenefit(
    icon: CupertinoIcons.rectangle_stack_fill,
    title: 'Multi-Chat',
    body:
        'Add every channel you mod or follow and switch between them from the chat bar - each keeps its own history.',
  ),
  ProBenefit(
    icon: CupertinoIcons.shield_fill,
    title: 'Full Moderation Toolkit',
    body:
        'Delete, timeout, ban, warn and clear a room with a tap - plus a live AutoMod queue and an unban-request inbox.',
  ),
  ProBenefit(
    icon: CupertinoIcons.smiley_fill,
    title: 'Emotes & Badges',
    body:
        'First-party and 7TV/BTTV emotes render inline, with a full picker and role badges across every chat.',
  ),
  ProBenefit(
    icon: CupertinoIcons.search_circle_fill,
    title: 'Smarter Chat',
    body:
        'Highlight mentions and keywords, mute what you don\'t want to see, and search your chat history.',
  ),
  ProBenefit(
    icon: CupertinoIcons.sparkles,
    title: 'What\'s Next',
    body:
        'Pro keeps growing - think stream health alerts and deeper platform tools. No dates promised, but the bench is full.',
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
  final PageController _pageController = PageController(viewportFraction: 0.88);

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
    final double textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1.0).clamp(1.0, 1.4);

    return ResponsiveWidgetWrapper(
      mobileWidget: Column(
        children: [
          SizedBox(
            height: 216.0 * textScale,
            child: PageView.builder(
              controller: this._pageController,
              itemCount: kProBenefits.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: ProBenefitCard(benefit: kProBenefits[index]),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SmoothPageIndicator(
            controller: this._pageController,
            count: kProBenefits.length,

            /// Unified page-dot grammar (same as the intro slides): worm
            /// effect, neutral active/inactive levels
            effect: WormEffect(
              dotHeight: 8.0,
              dotWidth: 8.0,
              spacing: AppSpacing.sm,
              dotColor: Theme.of(
                context,
              ).extension<AppTextColors>()!.textOrnament,
              activeDotColor: Theme.of(
                context,
              ).extension<AppTextColors>()!.textPrimary,
            ),
          ),
        ],
      ),

      /// Two-per-row grid built from however many benefits exist - a
      /// trailing odd card takes the row alone instead of hardcoding four
      tabletWidget: Column(
        children: [
          for (int i = 0; i < kProBenefits.length; i += 2) ...[
            if (i > 0) const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ProBenefitCard(benefit: kProBenefits[i])),
                if (i + 1 < kProBenefits.length) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: ProBenefitCard(benefit: kProBenefits[i + 1])),
                ] else
                  const Spacer(),
              ],
            ),
          ],
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
                color: Theme.of(
                  context,
                ).extension<AppTextColors>()!.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
