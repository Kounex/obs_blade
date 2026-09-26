import 'dart:math';

import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../utils/styling_helper.dart';

/// Content of one intro screen: an animated visual (told whether it is the
/// page on screen, so loops only run while visible) plus the copy block
class IntroPageData {
  final Widget Function(bool active) visual;
  final String eyebrow;
  final String title;
  final String body;
  final Widget? footer;

  /// Welcome screen: larger title
  final bool hero;

  /// Whether the visual sits on the framed [IntroStage] - false for visuals
  /// that bring their own frame (brand art, the device mockup)
  final bool framed;

  const IntroPageData({
    required this.visual,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.footer,
    this.hero = false,
    this.framed = true,
  });
}

/// Width above which a landscape-ish intro page puts visual and copy side by
/// side - same breakpoint as the rest of the app's tablet layouts
const double kIntroSideBySideMinWidth = StylingHelper.max_width_mobile;

/// Height reserved for the copy block in the stacked (phone) layout -
/// fits eyebrow, a two-line title and three body lines, plus the welcome
/// footnote
const double kIntroCopyMinHeight = 208.0;

/// One intro screen. Phone: visual on top, copy below. Wide + landscape:
/// visual and copy side by side. Scroll position drives a light parallax
/// (the visual lags the swipe, the copy fades out ahead of it)
class IntroPage extends StatefulWidget {
  final int index;
  final ValueNotifier<double> page;
  final IntroPageData data;

  const IntroPage({
    super.key,
    required this.index,
    required this.page,
    required this.data,
  });

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  late bool _active;

  @override
  void initState() {
    super.initState();
    _active = _isActive();
    this.widget.page.addListener(_onPage);
  }

  @override
  void dispose() {
    this.widget.page.removeListener(_onPage);
    super.dispose();
  }

  bool _isActive() => (this.widget.page.value - this.widget.index).abs() < 0.5;

  void _onPage() {
    final bool active = _isActive();
    if (active != _active) {
      setState(() => _active = active);
    }
  }

  Widget _parallax({
    required Widget child,
    required double lag,
    bool fade = false,
  }) {
    return AnimatedBuilder(
      animation: this.widget.page,
      child: child,
      builder: (context, child) {
        if (AppMotion.reduce(context)) return child!;
        final double delta = this.widget.index - this.widget.page.value;
        final double width = MediaQuery.sizeOf(context).width;
        Widget current = Transform.translate(
          offset: Offset(delta * width * lag, 0.0),
          child: child,
        );
        if (fade) {
          current = Opacity(
            opacity: (1.0 - delta.abs() * 1.6).clamp(0.0, 1.0),
            child: current,
          );
        } else {
          current = Transform.scale(
            scale: 1.0 - min(delta.abs(), 1.0) * 0.08,
            child: current,
          );
        }
        return current;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final IntroPageData data = this.widget.data;

    /// The visual is authored at a fixed size and scaled as a whole to the
    /// room it gets (up on tablets, down on small phones), capped so it
    /// never turns poster-sized
    final Widget visual = _parallax(
      lag: 0.3,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            width: min(constraints.maxWidth, 560.0),
            height: min(constraints.maxHeight, 520.0),

            /// Mockups are pictures of UI - they ignore the text scale
            /// (the copy next to them honours it)
            child: MediaQuery.withNoTextScaling(
              child: FittedBox(
                fit: BoxFit.contain,
                child: data.framed
                    ? IntroStage(child: data.visual(_active))
                    : data.visual(_active),
              ),
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool sideBySide =
            constraints.maxWidth > kIntroSideBySideMinWidth &&
            constraints.maxWidth > constraints.maxHeight;

        final Widget copy = _parallax(
          lag: 0.12,
          fade: true,

          /// Capped so large accessibility sizes can't push the visual
          /// out of the stacked layout
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: IntroCopy(
              data: data,
              textAlign: sideBySide ? TextAlign.left : TextAlign.center,
            ),
          ),
        );

        if (sideBySide) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl * 2),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: visual,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxl * 2),
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440.0),
                      child: copy,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xl,
                  ),
                  child: visual,
                ),
              ),

              /// Fixed-height copy slot (top-aligned) so the visual sits at
              /// the same height on every page while swiping - copy lengths
              /// differ per page
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440.0,
                  minHeight: kIntroCopyMinHeight,
                ),
                child: Align(alignment: Alignment.topCenter, child: copy),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

/// Eyebrow (accent caption) · title · body, plus an optional footer
class IntroCopy extends StatelessWidget {
  final IntroPageData data;
  final TextAlign textAlign;

  const IntroCopy({super.key, required this.data, required this.textAlign});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    /// Side-by-side (tablet) layout gets a larger type step to hold its own
    /// next to the scaled-up visual
    final bool wide = this.textAlign == TextAlign.left;
    final CrossAxisAlignment crossAlignment = this.textAlign == TextAlign.left
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAlignment,
      children: [
        StaggeredEntrance(
          index: 1,
          child: Text(
            this.data.eyebrow.toUpperCase(),
            textAlign: this.textAlign,
            style: textTheme.labelSmall!.copyWith(
              color: textColors.accentText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StaggeredEntrance(
          index: 2,
          child: Text(
            this.data.title,
            textAlign: this.textAlign,
            style: textTheme.displaySmall!.copyWith(
              fontSize: (this.data.hero ? 36.0 : 30.0) * (wide ? 1.3 : 1.0),
              height: 1.12,
              letterSpacing: -0.6,
              color: textColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StaggeredEntrance(
          index: 3,
          child: Text(
            this.data.body,
            textAlign: this.textAlign,
            style: textTheme.bodyLarge!.copyWith(
              fontSize: wide ? 17.0 : null,
              height: 1.45,
              color: textColors.textSecondary,
            ),
          ),
        ),
        if (this.data.footer != null) ...[
          const SizedBox(height: AppSpacing.lg),
          StaggeredEntrance(index: 4, child: this.data.footer!),
        ],
      ],
    );
  }
}

/// Framed "stage" the feature mockups sit on: a card-colored panel with a
/// hairline border and a soft accent glow. Mockups are designed at a fixed
/// [kIntroStageSize] and the stage is scaled as a whole ([FittedBox] in
/// [IntroPage]), so every screen size shows the identical composition
const Size kIntroStageSize = Size(360.0, 340.0);

class IntroStage extends StatelessWidget {
  final Widget child;

  const IntroStage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: kIntroStageSize.width,
      height: kIntroStageSize.height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28.0),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              accent.withValues(alpha: dark ? 0.07 : 0.04),
              Theme.of(context).cardColor,
            ),
            Theme.of(context).cardColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: dark ? 0.10 : 0.08),
            blurRadius: 48.0,
            spreadRadius: -8.0,
            offset: const Offset(0.0, 16.0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: this.child,
    );
  }
}

/// Soft accent wash at the top of the intro that drifts with the swipe
class IntroBackdrop extends StatelessWidget {
  final ValueNotifier<double> page;

  const IntroBackdrop({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: this.page,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6 + (this.page.value * 0.4) % 1.6, -1.1),
              radius: 1.1,
              colors: [
                accent.withValues(alpha: dark ? 0.14 : 0.08),
                accent.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual widget base for the intro mockups - [active] is true while the
/// page is the one on screen
abstract class IntroVisual extends StatefulWidget {
  final bool active;

  const IntroVisual({super.key, required this.active});
}

/// Drives an intro mockup's looping storyboard: [loop] runs 0 → 1 over
/// [period] and repeats while the page is on screen, restarts from the top
/// when the page comes back, and parks at [restValue] (a representative
/// frame) under reduced motion
abstract class IntroLoopState<T extends IntroVisual> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController loop;

  Duration get period;

  /// Storyboard frame shown when motion is reduced
  double get restValue;

  @override
  void initState() {
    super.initState();
    loop = AnimationController(vsync: this, duration: this.period);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(restart: !loop.isAnimating);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != this.widget.active) {
      _sync(restart: this.widget.active);
    }
  }

  void _sync({required bool restart}) {
    if (AppMotion.reduce(context)) {
      loop.stop();
      loop.value = this.restValue;
      return;
    }
    if (this.widget.active) {
      if (restart) loop.value = 0.0;
      if (!loop.isAnimating) loop.repeat();
    } else {
      loop.stop();
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }

  /// Progress (0 → 1, eased) of [t] through the storyboard window
  /// [begin, end]
  double window(
    double begin,
    double end, [
    Curve curve = AppMotion.emphasized,
  ]) => curve.transform(((loop.value - begin) / (end - begin)).clamp(0.0, 1.0));
}
