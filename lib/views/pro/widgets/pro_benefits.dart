import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../models/enums/chat_type.dart';
import '../../../shared/design/design.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/responsive_widget_wrapper.dart';
import '../../../types/extensions/string.dart';
import '../../../utils/built_in_themes.dart';
import '../../dashboard/widgets/obs_widgets/stream_chat/combined_chat_icon.dart';
import 'pro_palette.dart';

/// Which illustration a benefit card renders above its copy
enum ProBenefitVisual { platforms, moderation, chatTools, themes }

/// One browsable Pro benefit. Copy rule (monetization strategy):
/// honest, no dates promised for unreleased features.
class ProBenefit {
  final IconData icon;
  final String title;
  final String body;

  /// Identity hue - card wash, border and the icon tile
  final Color color;

  final ProBenefitVisual visual;

  /// Short feature tags listed under the body
  final List<String> tags;

  const ProBenefit({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.visual,
    this.tags = const [],
  });
}

/// Four themed cards (was eight single-feature cards): chat everywhere,
/// moderation, chat tools, themes. The native-chat upsell in the chat pane
/// lists titles from here as its benefit taste.
const List<ProBenefit> kProBenefits = [
  ProBenefit(
    icon: CupertinoIcons.chat_bubble_2_fill,
    title: 'Every Chat, One Place',
    body:
        'Native Twitch, Kick and YouTube chat - on their own or merged into one live timeline. Replies land on the right platform.',
    color: ProPalette.twitch,
    visual: ProBenefitVisual.platforms,
    tags: ['Combined chat', 'Saved combos', 'Who\'s live'],
  ),
  ProBenefit(
    icon: CupertinoIcons.shield_fill,
    title: 'Moderate From Your Pocket',
    body:
        'Delete, timeout and ban on every platform - plus AutoMod, unban requests and chat modes on Twitch.',
    color: ProPalette.moderation,
    visual: ProBenefitVisual.moderation,
    tags: ['AutoMod', 'Unban requests', 'Chat modes'],
  ),
  ProBenefit(
    icon: CupertinoIcons.sparkles,
    title: 'Chat, Supercharged',
    body:
        '7TV, BTTV and FFZ emotes inline, an emote picker and badges - plus mention highlights, muted words and chat search.',
    color: ProPalette.chat,
    visual: ProBenefitVisual.chatTools,
    tags: ['7TV · BTTV · FFZ', 'Highlights', 'Search'],
  ),
  ProBenefit(
    icon: CupertinoIcons.paintbrush_fill,
    title: 'Make It Yours',
    body:
        'Design your own color themes and switch anytime. Pro keeps growing - stream health alerts are on the bench, no dates promised.',
    color: ProPalette.themes,
    visual: ProBenefitVisual.themes,
    tags: ['Custom themes', 'More coming'],
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

  /// Page the dots and card depth follow (fractional while swiping)
  double _page = 0.0;

  @override
  void initState() {
    super.initState();
    this._pageController.addListener(this._onScroll);
  }

  void _onScroll() {
    if (!this._pageController.hasClients) return;
    final double page = this._pageController.page ?? 0.0;
    if (page != this._page) setState(() => this._page = page);
  }

  @override
  void dispose() {
    this._pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Active dot takes the current card's identity hue, blended while
    /// swiping between two cards
    final int lower = this._page.floor().clamp(0, kProBenefits.length - 1);
    final int upper = this._page.ceil().clamp(0, kProBenefits.length - 1);
    final Color activeDot = ProPalette.ink(
      context,
      Color.lerp(
        kProBenefits[lower].color,
        kProBenefits[upper].color,
        (this._page - lower).clamp(0.0, 1.0),
      )!,
    );

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
                          child: ProBenefitCard(benefit: benefit, fill: false),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: PageView.builder(
                    controller: this._pageController,
                    itemCount: kProBenefits.length,
                    itemBuilder: (context, index) {
                      /// Off-center cards settle back slightly - depth while
                      /// swiping, flat at rest
                      final double distance = (this._page - index).abs().clamp(
                        0.0,
                        1.0,
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Transform.scale(
                          scale: 1.0 - 0.04 * distance,
                          child: ProBenefitCard(benefit: kProBenefits[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SmoothPageIndicator(
            controller: this._pageController,
            count: kProBenefits.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8.0,
              dotWidth: 8.0,
              expansionFactor: 3.0,
              spacing: AppSpacing.sm,
              dotColor: Theme.of(
                context,
              ).extension<AppTextColors>()!.textOrnament,
              activeDotColor: activeDot,
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

class ProBenefitCard extends StatelessWidget {
  final ProBenefit benefit;

  /// Pins the tags to the bottom edge of a bounded slot. False lays the
  /// card out at its natural height (the carousel's sizing pass)
  final bool fill;

  const ProBenefitCard({super.key, required this.benefit, this.fill = true});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Theme.of(context).cardColor;
    final Color ink = ProPalette.ink(context, this.benefit.color);
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    /// Own card surface instead of BaseCard: BaseCard shrink-wraps its
    /// child in a Column, but this card fills its carousel / grid slot so
    /// the tags can sit on the bottom edge (Spacer). Same radius as the
    /// card contract, hairline in the identity hue
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBaseCardBorderRadius),
        border: Border.all(color: this.benefit.color.withValues(alpha: 0.28)),

        /// Identity wash: a soft radial glow of the card's hue from the
        /// top-right corner, fading into the regular card fill
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.4,
          colors: [
            Color.alphaBlend(
              this.benefit.color.withValues(alpha: 0.20),
              cardColor,
            ),
            cardColor,
          ],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 56.0, child: _BenefitVisual(benefit: this.benefit)),
          const SizedBox(height: AppSpacing.md),
          Text(
            this.benefit.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            this.benefit.body,
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: textColors.textSecondary),
          ),
          if (this.fill) const Spacer(),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final String tag in this.benefit.tags)
                _Tag(text: tag, color: this.benefit.color, ink: ink),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color ink;

  const _Tag({required this.text, required this.color, required this.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3.0,
      ),
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.14),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        this.text,
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(color: this.ink, letterSpacing: 0.2),
      ),
    );
  }
}

/// Glowing squircle tile in an identity hue (the paywall's colourful
/// counterpart to the neutral DecorativeIconTile)
class ProGlowTile extends StatelessWidget {
  final Color color;
  final double size;
  final Widget child;

  const ProGlowTile({
    super.key,
    required this.color,
    required this.child,
    this.size = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: this.size,
      height: this.size,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            this.color.withValues(alpha: 0.30),
            this.color.withValues(alpha: 0.12),
          ],
        ),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(this.size * 0.38),
          side: BorderSide(color: this.color.withValues(alpha: 0.55)),
        ),
        shadows: [
          BoxShadow(
            color: this.color.withValues(alpha: 0.30),
            blurRadius: 16.0,
          ),
        ],
      ),
      child: Center(child: this.child),
    );
  }
}

class _BenefitVisual extends StatelessWidget {
  final ProBenefit benefit;

  const _BenefitVisual({required this.benefit});

  Widget _iconTile(BuildContext context) => ProGlowTile(
    color: this.benefit.color,
    child: Icon(
      this.benefit.icon,
      size: 26.0,
      color: ProPalette.ink(context, this.benefit.color),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return switch (this.benefit.visual) {
      /// The three platform marks in their brand colours, merging into the
      /// combined-chat mark
      ProBenefitVisual.platforms => Row(
        children: [
          for (final ChatType type in const [
            ChatType.Twitch,
            ChatType.Kick,
            ChatType.YouTube,
          ]) ...[
            ProGlowTile(
              color: ProPalette.brand(type),
              child: chatTypeIcon(
                context,
                type,
                size: 26.0,
                color: ProPalette.platformInk(context, type),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Icon(
            CupertinoIcons.arrow_right,
            size: 16.0,
            color: Theme.of(context).extension<AppTextColors>()!.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          const ProGlowTile(
            color: ProPalette.chat,
            child: CombinedChatIcon(size: 30.0),
          ),
        ],
      ),

      /// Shield plus the actions it covers
      ProBenefitVisual.moderation => Row(
        children: [
          this._iconTile(context),
          const SizedBox(width: AppSpacing.md),
          const _MiniChip(
            icon: CupertinoIcons.trash_fill,
            color: ProPalette.youtube,
          ),
          const SizedBox(width: AppSpacing.sm),
          const _MiniChip(
            icon: CupertinoIcons.timer_fill,
            color: ProPalette.moderation,
          ),
          const SizedBox(width: AppSpacing.sm),
          const _MiniChip(
            icon: CupertinoIcons.hammer_fill,
            color: ProPalette.twitch,
          ),
        ],
      ),

      /// Emotes, mention highlights, search
      ProBenefitVisual.chatTools => Row(
        children: [
          this._iconTile(context),
          const SizedBox(width: AppSpacing.md),
          const _MiniChip(
            icon: CupertinoIcons.smiley_fill,
            color: Color(0xFFFFD60A),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _MiniChip(
            icon: CupertinoIcons.at_circle_fill,
            color: ProPalette.chat,
          ),
          const SizedBox(width: AppSpacing.sm),
          const _MiniChip(
            icon: CupertinoIcons.search,
            color: ProPalette.twitch,
          ),
        ],
      ),

      /// The built-in themes as swatches (accent dot over background)
      ProBenefitVisual.themes => Row(
        children: [
          this._iconTile(context),
          const SizedBox(width: AppSpacing.md),
          for (final theme in BuiltInThemes.themes) ...[
            _ThemeSwatch(
              background: theme.backgroundColorHex.hexToColor(),
              accent: theme.accentColorHex.hexToColor(),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    };
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniChip({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36.0,
      height: 36.0,
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        this.icon,
        size: 18.0,
        color: ProPalette.ink(context, this.color),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final Color background;
  final Color accent;

  const _ThemeSwatch({required this.background, required this.accent});

  @override
  Widget build(BuildContext context) {
    final bool dark = ProPalette.darkSurface(context);
    return Container(
      width: 30.0,
      height: 30.0,
      decoration: BoxDecoration(
        color: this.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: (dark ? Colors.white : Colors.black).withValues(alpha: 0.18),
        ),
      ),
      child: Center(
        child: Container(
          width: 14.0,
          height: 14.0,
          decoration: BoxDecoration(color: this.accent, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
