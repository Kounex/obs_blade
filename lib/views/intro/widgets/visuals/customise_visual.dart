import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';

import '../../../settings/widgets/decorative_icon_tile.dart';
import '../intro_page.dart';
import 'mock_kit.dart';

/// Customisation mockup, two beats:
/// 1. Feature switches flip on one by one (Studio Mode, Recording / Replay
///    Controls, Hotkeys) and each lights up its piece on a mini dashboard
///    underneath - PGM / PVW tallies + Transition, record / replay buttons,
///    hotkey chips.
/// 2. The Elements Order list: a row lifts and is dragged into place.
class CustomiseVisual extends IntroVisual {
  const CustomiseVisual({super.key, required super.active});

  @override
  State<CustomiseVisual> createState() => _CustomiseVisualState();
}

class _Feature {
  final IconData icon;
  final String title;

  const _Feature(this.icon, this.title);
}

class _CustomiseVisualState extends IntroLoopState<CustomiseVisual> {
  /// Same row icons as Settings / Customisation
  static const List<_Feature> _features = [
    _Feature(CupertinoIcons.film, 'Studio Mode'),
    _Feature(CupertinoIcons.recordingtape, 'Recording Controls'),
    _Feature(CupertinoIcons.reply_thick_solid, 'Replay Controls'),
    _Feature(CupertinoIcons.square_grid_3x2_fill, 'Hotkeys'),
  ];

  /// Loop time each feature switch flips on
  static const List<double> _flipAt = [0.08, 0.17, 0.26, 0.35];

  @override
  Duration get period => const Duration(seconds: 13);

  @override
  double get restValue => 0.5;

  bool _on(int feature) => loop.value >= _flipAt[feature];

  /// Reveal (0..1) of a feature's piece on the mini dashboard
  double _reveal(int feature) =>
      window(_flipAt[feature] + 0.01, _flipAt[feature] + 0.06);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kIntroStageSize,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          /// Beat 1 → beat 2 crossfade, and back at the loop end
          final double beat = window(0.5, 0.56) * (1.0 - window(0.95, 1.0));
          return Stack(
            fit: StackFit.expand,
            children: [
              if (beat < 1.0)
                Opacity(
                  opacity: 1.0 - beat,
                  child: Transform.translate(
                    offset: Offset(-24.0 * beat, 0.0),
                    child: _featuresBeat(context),
                  ),
                ),
              if (beat > 0.0)
                Opacity(
                  opacity: beat,
                  child: Transform.translate(
                    offset: Offset(24.0 * (1.0 - beat), 0.0),
                    child: _order(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    return Row(
      children: [
        Icon(
          CupertinoIcons.chevron_left,
          size: 16.0,
          color: textColors.highlightText,
        ),
        const SizedBox(width: 2.0),
        Text(
          'Settings',
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.labelMedium!.copyWith(color: textColors.highlightText),
        ),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
              fontWeight: FontWeight.w600,
              color: textColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 60.0),
      ],
    );
  }

  Widget _featuresBeat(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, 'Customisation'),
          const SizedBox(height: AppSpacing.md),
          MockCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                for (int i = 0; i < _features.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1.0,
                      indent: 36.0,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.4),
                    ),
                  SizedBox(
                    height: 38.0,
                    child: Row(
                      children: [
                        DecorativeIconTile(
                          icon: _features[i].icon,
                          size: 26.0,
                          iconSize: 15.0,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _features[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall,
                          ),
                        ),
                        IgnorePointer(
                          child: Transform.scale(
                            scale: 0.72,
                            child: BaseAdaptiveSwitch(
                              value: _on(i),
                              onChanged: (_) {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: _miniDashboard(context)),
        ],
      ),
    );
  }

  /// The dashboard reacting to the switches above: scene tiles gain PGM /
  /// PVW tallies + a Transition button with Studio Mode, the control row
  /// fills in as the other features flip on
  Widget _miniDashboard(BuildContext context) {
    final bool studio = _reveal(0) > 0.5;
    return MockCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const MockSceneTile(
                name: 'Game',
                program: true,
                width: 72.0,
                height: 44.0,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              MockSceneTile(
                name: 'Chat',
                preview: studio,
                width: 72.0,
                height: 44.0,
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: _reveals(
                  0,
                  _chip(
                    context,
                    'Transition',
                    CupertinoIcons.arrow_right_arrow_left,
                    height: 44.0,
                  ),
                  height: 44.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              Expanded(
                child: _reveals(
                  1,
                  _chip(
                    context,
                    'Record',
                    CupertinoIcons.largecircle_fill_circle,
                    accent: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: _reveals(
                  2,
                  _chip(context, 'Replay', CupertinoIcons.reply_thick_solid),
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: _reveals(
                  3,
                  _chip(context, 'Mute Mic', CupertinoIcons.mic_slash_fill),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Placeholder outline until [feature] flips on, then the piece pops in
  Widget _reveals(int feature, Widget child, {double height = 28.0}) {
    final double t = _reveal(feature);
    return Stack(
      children: [
        Opacity(
          opacity: 1.0 - t,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm - 2),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: t,
          child: Transform.scale(
            scale: lerpDouble(0.85, 1.0, t)!,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    String text,
    IconData? icon, {
    bool accent = false,
    double height = 28.0,
  }) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;
    final Color color = accent
        ? statusColors.recording
        : Theme.of(context).extension<AppTextColors>()!.textSecondary;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: accent
            ? statusColors.recording.withValues(alpha: 0.14)
            : Theme.of(context).dividerColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.sm - 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.0, color: color),
            const SizedBox(width: 3.0),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 10.0,
                letterSpacing: 0.0,
                color: accent ? statusColors.recordingText : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _order(BuildContext context) {
    const List<(IconData, String)> elements = [
      (CupertinoIcons.film_fill, 'Scenes'),
      (CupertinoIcons.tv_fill, 'Scene Preview'),
      (CupertinoIcons.speaker_2_fill, 'Audio'),
      (CupertinoIcons.chart_bar_alt_fill, 'Stats'),
    ];
    const double rowHeight = 46.0;
    const double gap = AppSpacing.sm;
    const double slot = rowHeight + gap;

    /// "Audio" (index 2) lifts, travels up to slot 0, drops; the rows it
    /// passes shift down one slot
    final double lift = window(0.6, 0.64) * (1.0 - window(0.8, 0.84));
    final double travel = window(0.64, 0.8, Curves.easeInOutCubic);

    double offsetOf(int index) {
      if (index == 2) return (2 - 2 * travel) * slot;
      if (index < 2) return (index + travel) * slot;
      return index * slot;
    }

    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    Widget row(int index) {
      final bool dragged = index == 2;
      return Transform.scale(
        scale: dragged ? 1.0 + lift * 0.04 : 1.0,
        child: Container(
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: dragged && lift > 0
                  ? Theme.of(context).buttonTheme.colorScheme!.secondary
                        .withValues(alpha: 0.6 * lift)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.4),
            ),
            boxShadow: [
              if (dragged)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35 * lift),
                  blurRadius: 18.0,
                  offset: Offset(0.0, 8.0 * lift),
                ),
            ],
          ),
          child: Row(
            children: [
              DecorativeIconTile(
                icon: elements[index].$1,
                size: 26.0,
                iconSize: 14.0,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  elements[index].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(
                CupertinoIcons.line_horizontal_3,
                size: 18.0,
                color: dragged && lift > 0
                    ? textColors.textPrimary
                    : textColors.textTertiary,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context, 'Elements Order'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Drag to arrange the Dashboard.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: slot * elements.length,
            child: Stack(
              children: [
                /// Dragged row painted last so it floats above the rest
                for (final int index in [0, 1, 3, 2])
                  Positioned(
                    left: 0.0,
                    right: 0.0,
                    top: offsetOf(index),
                    child: row(index),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
