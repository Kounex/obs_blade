import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../utils/styling_helper.dart';
import '../../../dashboard/widgets/dashboard_content/scene_buttons/scene_button.dart';

/// Realistic, state-free replicas of dashboard leaves for the intro
/// mockups. They follow the same tokens / color contracts as the real
/// widgets (scene tile program ring + tint, meter gradient, card hairline)
/// but take plain values instead of reading [DashboardStore].

/// Scene tile - [SelectableBox] geometry with the program tint + ring and
/// an optional PGM / PVW tally tag
class MockSceneTile extends StatelessWidget {
  final String name;
  final bool program;
  final bool preview;
  final double width;
  final double height;

  const MockSceneTile({
    super.key,
    required this.name,
    this.program = false,
    this.preview = false,
    this.width = 96.0,
    this.height = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;
    final Color card = StylingHelper.lightenDarkenColor(
      Theme.of(context).cardColor,
      4,
    );

    return Stack(
      children: [
        AnimatedContainer(
          duration: AppMotion.slow,
          curve: AppMotion.standard,
          width: this.width,
          height: this.height,
          alignment: Alignment.center,

          /// Leaves room for the tally tag under the name
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            0.0,
            AppSpacing.sm,
            this.program || this.preview ? 14.0 : 0.0,
          ),
          decoration: BoxDecoration(
            color: this.program
                ? Color.alphaBlend(
                    statusColors.program.withValues(alpha: 0.10),
                    card,
                  )
                : card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: this.program
                  ? statusColors.program
                  : this.preview
                  ? statusColors.live.withValues(alpha: 0.7)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            this.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Positioned(
          left: 4.0,
          bottom: 4.0,
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                alignment: Alignment.bottomLeft,
                child: child,
              ),
            ),
            child: this.program || this.preview
                ? SceneTallyChip(
                    key: ValueKey(this.program),
                    label: this.program ? 'PGM' : 'PVW',
                    isProgram: this.program,
                  )
                : const SizedBox(key: ValueKey('none')),
          ),
        ),
      ],
    );
  }
}

/// Audio row - name, level meter (live-green gradient, near-clip turns
/// hot), mute glyph
class MockAudioRow extends StatelessWidget {
  final String name;
  final double level;
  final bool muted;

  const MockAudioRow({
    super.key,
    required this.name,
    required this.level,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStatusColors statusColors = theme.extension<AppStatusColors>()!;
    final AppTextColors textColors = theme.extension<AppTextColors>()!;
    final bool hot = this.level >= 0.9;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                this.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium!.copyWith(
                  color: textColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6.0),
              Opacity(
                opacity: this.muted ? 0.35 : 1.0,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: theme.disabledColor.withValues(alpha: 0.6),
                          borderRadius: AppRadius.pill,
                        ),
                      ),
                      Container(
                        height: 6.0,
                        width:
                            constraints.maxWidth * this.level.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.pill,
                          gradient: LinearGradient(
                            colors: hot
                                ? [
                                    statusColors.live.withValues(alpha: 0.75),
                                    statusColors.live.withValues(alpha: 0.75),
                                    statusColors.recording.withValues(
                                      alpha: 0.85,
                                    ),
                                  ]
                                : [
                                    statusColors.live.withValues(alpha: 0.55),
                                    statusColors.live.withValues(alpha: 0.90),
                                  ],
                            stops: hot ? const [0.0, 0.7, 1.0] : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Icon(
          this.muted
              ? CupertinoIcons.speaker_slash_fill
              : CupertinoIcons.speaker_2_fill,
          size: 16.0,
          color: this.muted ? statusColors.recording : textColors.textSecondary,
        ),
      ],
    );
  }
}

/// Program monitor - a tiny "scene" drawn in code (gradient backdrop, a
/// webcam bubble and a lower third) that cross-fades per active scene
class MockProgramMonitor extends StatelessWidget {
  final int scene;
  final double width;
  final double height;

  const MockProgramMonitor({
    super.key,
    required this.scene,
    required this.width,
    required this.height,
  });

  static const List<List<Color>> _backdrops = [
    [Color(0xFF3A1C71), Color(0xFFD76D77)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF1D2B64), Color(0xFF6A82FB)],
  ];

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = _backdrops[this.scene % _backdrops.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: this.width,
        height: this.height,
        child: AnimatedSwitcher(
          duration: AppMotion.slow,
          child: Container(
            key: ValueKey(this.scene),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: Stack(
              children: [
                if (this.scene == 0)
                  Center(
                    child: Icon(
                      CupertinoIcons.game_controller_solid,
                      size: this.height * 0.4,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                if (this.scene == 1)
                  Center(
                    child: Icon(
                      CupertinoIcons.person_crop_square_fill,
                      size: this.height * 0.45,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                if (this.scene == 2)
                  Center(
                    child: Text(
                      'BE RIGHT BACK',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w800,
                        fontSize: this.height * 0.11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                if (this.scene == 0)
                  Positioned(
                    right: this.width * 0.05,
                    bottom: this.height * 0.08,
                    child: Container(
                      width: this.height * 0.3,
                      height: this.height * 0.3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: this.height * 0.17,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                Positioned(
                  left: this.width * 0.05,
                  bottom: this.height * 0.08,
                  child: Container(
                    width: this.width * 0.36,
                    height: this.height * 0.1,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Plain card surface for mock sections (card fill + hairline)
class MockCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const MockCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: this.padding,
      decoration: BoxDecoration(
        color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor, 3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: this.child,
    );
  }
}

/// Section caption used inside mock cards
class MockCaption extends StatelessWidget {
  final String text;

  const MockCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      this.text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall!.copyWith(
        color: Theme.of(context).extension<AppTextColors>()!.textTertiary,
        fontSize: 10.0,
      ),
    );
  }
}

/// Pseudo-random but smooth audio level for meter mockups: layered sines
/// per channel [seed], sampled at loop time [t] (0..1). Whole-number cycle
/// counts keep the loop seamless; [cycles] scales them to the loop period
double mockLevel(
  double t,
  int seed, {
  double base = 0.55,
  double swing = 0.3,
  int cycles = 20,
}) {
  final double phase = seed * 1.7;
  final double v =
      sin(t * 2 * pi * cycles + phase) * 0.5 +
      sin(t * 2 * pi * (cycles * 2 - 3) + phase * 2) * 0.3 +
      sin(t * 2 * pi * (cycles * 3 + 7) + phase * 3) * 0.2;
  return (base + v * swing).clamp(0.05, 0.97);
}
