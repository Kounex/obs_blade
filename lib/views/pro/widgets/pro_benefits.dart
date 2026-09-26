import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../models/enums/chat_type.dart';
import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/responsive_widget_wrapper.dart';
import '../../dashboard/widgets/obs_widgets/stream_chat/combined_chat_icon.dart';
import 'pro_palette.dart';

/// One browsable Pro benefit. Copy rule (monetization strategy):
/// honest, no dates promised for unreleased features.
class ProBenefit {
  final IconData icon;
  final String title;
  final String body;

  /// Fill of the benefit's icon tile - the card itself stays neutral
  final Color color;

  /// Replaces the single icon tile with the platform marks
  final bool showPlatforms;

  const ProBenefit({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.showPlatforms = false,
  });
}

/// Four themed cards (was eight single-feature cards). The native-chat
/// upsell in the chat pane lists titles from here as its benefit taste.
const List<ProBenefit> kProBenefits = [
  ProBenefit(
    icon: CupertinoIcons.chat_bubble_2_fill,
    title: 'Every Chat, One Place',
    body:
        'Native Twitch, Kick and YouTube chat - on their own or merged into one timeline. Save your channel combos, see who\'s live, and replies land on the right platform.',
    color: ProPalette.twitch,
    showPlatforms: true,
  ),
  ProBenefit(
    icon: CupertinoIcons.shield_fill,
    title: 'Moderate From Your Pocket',
    body:
        'Delete, timeout and ban on every platform - plus AutoMod, unban requests and chat modes on Twitch.',
    color: ProPalette.moderation,
  ),
  ProBenefit(
    icon: CupertinoIcons.smiley_fill,
    title: 'Chat, Supercharged',
    body:
        '7TV, BTTV and FFZ emotes, an emote picker and badges - plus mention highlights, muted words and chat search.',
    color: ProPalette.chatTools,
  ),
  ProBenefit(
    icon: CupertinoIcons.paintbrush_fill,
    title: 'Make It Yours',
    body:
        'Design your own color themes and switch anytime. Pro keeps growing - stream health alerts are on the bench, no dates promised.',
    color: ProPalette.themes,
  ),
];

/// Browsable benefits: a swipeable card carousel with page dots on phone,
/// a two-column grid on tablet (design system § Responsive layouts).
///
/// Laid out full-bleed by the parent: the phone carousel runs to the
/// screen edges (cards slide in and out there instead of being clipped at
/// the content gutter), the tablet grid insets itself by [gutter].
class ProBenefitsBrowser extends StatefulWidget {
  /// Horizontal content gutter of the surrounding column
  final double gutter;

  const ProBenefitsBrowser({super.key, this.gutter = AppSpacing.lg});

  @override
  State<ProBenefitsBrowser> createState() => _ProBenefitsBrowserState();
}

class _ProBenefitsBrowserState extends State<ProBenefitsBrowser> {
  /// With [AppSpacing.xs] on each side of a page, 0.94 rests the centered
  /// card within ~1px of the [AppSpacing.lg] content gutter across phone
  /// widths (360-430) - aligned with the hero and pricing cards, with the
  /// neighbours peeking in from the screen edge
  final PageController _pageController = PageController(viewportFraction: 0.94);

  @override
  void dispose() {
    this._pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    return ResponsiveWidgetWrapper(
      mobileWidget: Column(
        children: [
          /// PageView needs a bounded height: every card is laid out
          /// invisibly at page width underneath, so the carousel takes the
          /// tallest card's height at any text scale / copy length. Full
          /// width, so the PageView (not the sizing cards) sets the width
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                for (final ProBenefit benefit in kProBenefits)
                  ExcludeSemantics(
                    child: Visibility(
                      visible: false,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: FractionallySizedBox(
                        widthFactor: this._pageController.viewportFraction,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: ProBenefitCard(benefit: benefit),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
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
              ],
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
              dotColor: textColors.textOrnament,
              activeDotColor: textColors.textPrimary,
            ),
          ),
        ],
      ),

      /// Two-per-row grid built from however many benefits exist - a
      /// trailing odd card takes the row alone instead of hardcoding four.
      /// IntrinsicHeight keeps each row's pair the same height
      tabletWidget: Padding(
        padding: EdgeInsets.symmetric(horizontal: this.widget.gutter),
        child: Column(
          children: [
            for (int i = 0; i < kProBenefits.length; i += 2) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: ProBenefitCard(benefit: kProBenefits[i])),
                    if (i + 1 < kProBenefits.length) ...[
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: ProBenefitCard(benefit: kProBenefits[i + 1]),
                      ),
                    ] else
                      const Spacer(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Neutral liquid card: one coloured icon tile (or the platform marks),
/// title, body.
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
            if (this.benefit.showPlatforms)
              const _PlatformTiles()
            else
              ProIconTile(
                color: this.benefit.color,
                child: Icon(
                  this.benefit.icon,
                  size: 22.0,
                  color: ProPalette.onFill(this.benefit.color),
                ),
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

/// Solid squircle icon tile (iOS settings-icon idiom) - same shape
/// contract as the neutral DecorativeIconTile
class ProIconTile extends StatelessWidget {
  final Color color;
  final Widget child;
  final double size;

  const ProIconTile({
    super.key,
    required this.color,
    required this.child,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color card = Theme.of(context).cardColor;

    /// A fill close to the card (Kick's green on light cards, the neutral
    /// combined tile) gets a hairline so the tile keeps its edge
    final Color fill = Color.alphaBlend(this.color, card);
    final double lighter =
        (fill.computeLuminance() > card.computeLuminance()
            ? fill.computeLuminance()
            : card.computeLuminance()) +
        0.05;
    final double darker =
        (fill.computeLuminance() > card.computeLuminance()
            ? card.computeLuminance()
            : fill.computeLuminance()) +
        0.05;
    final bool needsEdge = lighter / darker < 1.6;
    final bool darkCard = card.computeLuminance() <= 0.2;

    return Container(
      width: this.size,
      height: this.size,
      decoration: ShapeDecoration(
        color: this.color,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(this.size * 0.38),
          side: needsEdge
              ? BorderSide(
                  color: (darkCard ? Colors.white : Colors.black).withValues(
                    alpha: 0.14,
                  ),
                )
              : BorderSide.none,
        ),
      ),
      child: Center(child: this.child),
    );
  }
}

/// Twitch, Kick and YouTube marks on their brand fills, then the combined
/// mark on a neutral tile
class _PlatformTiles extends StatelessWidget {
  const _PlatformTiles();

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).cardColor.computeLuminance() <= 0.2;

    return Row(
      children: [
        for (final ChatType type in const [
          ChatType.Twitch,
          ChatType.Kick,
          ChatType.YouTube,
        ]) ...[
          ProIconTile(
            color: ProPalette.brand(type),
            child: chatTypeIcon(
              context,
              type,
              size: 22.0,
              color: ProPalette.onFill(ProPalette.brand(type)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        ProIconTile(
          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.07),
          child: const CombinedChatIcon(size: 24.0),
        ),
      ],
    );
  }
}
