import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../dashboard/widgets/obs_widgets/stats/stat_tile.dart';
import '../intro_page.dart';
import 'mock_kit.dart';

/// Stats mockup: the real [StatTile]s ticking live (FPS / CPU / bitrate
/// count up on each tick), a bitrate sparkline drawing itself, and a short
/// history of past sessions sliding in underneath
class StatsVisual extends IntroVisual {
  const StatsVisual({super.key, required super.active});

  @override
  State<StatsVisual> createState() => _StatsVisualState();
}

class _StatsVisualState extends IntroLoopState<StatsVisual> {
  /// Readout ticks per loop (the dashboard's 1 s cadence, sped up)
  static const int _ticks = 10;

  @override
  Duration get period => const Duration(seconds: 10);

  @override
  double get restValue => 0.85;

  int get _tick => (loop.value * _ticks).floor();

  /// Deterministic jitter per tick and channel
  double _jitter(int channel) {
    final double x = sin((_tick + 1) * 12.9898 + channel * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: kIntroStageSize,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'FPS',
                      text: (59.8 + _jitter(0) * 0.2).toStringAsFixed(1),
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatTile(
                      label: 'CPU',
                      text: (9.0 + _jitter(1) * 6.0).toStringAsFixed(1),
                      unit: '%',
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StatTile(
                      label: 'kbit/s',
                      text: (5800 + _jitter(2) * 500).toStringAsFixed(0),
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              MockCard(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MockCaption('Bitrate'),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      height: 44.0,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SparklinePainter(
                          progress: window(0.0, 0.7, Curves.easeInOut),
                          color: Theme.of(
                            context,
                          ).extension<AppStatusColors>()!.live,
                          grid: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const MockCaption('Past sessions'),
              const SizedBox(height: AppSpacing.sm),
              _session(
                context,
                0,
                icon: CupertinoIcons.dot_radiowaves_left_right,
                title: 'Friday stream',
                meta: '3:12:40 · 6.1k kbit/s',
              ),
              const SizedBox(height: AppSpacing.xs),
              _session(
                context,
                1,
                icon: CupertinoIcons.recordingtape,
                title: 'Tutorial recording',
                meta: '0:48:05 · 1080p60',
              ),
              const SizedBox(height: AppSpacing.xs),
              _session(
                context,
                2,
                icon: CupertinoIcons.dot_radiowaves_left_right,
                title: 'Community night',
                meta: '2:05:13 · 5.8k kbit/s',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _session(
    BuildContext context,
    int index, {
    required IconData icon,
    required String title,
    required String meta,
  }) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    final double t = window(0.3 + index * 0.08, 0.42 + index * 0.08);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0.0, 10.0 * (1.0 - t)),
        child: MockCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 16.0, color: textColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Flexible(
                flex: 4,
                child: Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: textColors.textTertiary,
                    fontFeatures: kTabularFigures,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                CupertinoIcons.chevron_right,
                size: 12.0,
                color: textColors.textOrnament,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bitrate line drawing in from the left with a soft fill under it
class _SparklinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color grid;

  _SparklinePainter({
    required this.progress,
    required this.color,
    required this.grid,
  });

  static const int _points = 40;

  double _value(int i) =>
      0.55 +
      sin(i * 0.45) * 0.18 +
      sin(i * 1.3 + 1.0) * 0.08 +
      (i > 27 && i < 31 ? -0.25 : 0.0);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = this.grid
      ..strokeWidth = 1.0;
    for (int i = 1; i < 3; i++) {
      final double y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final int visible = max(2, (_points * this.progress).round());
    final Path line = Path();
    for (int i = 0; i < visible; i++) {
      final Offset p = Offset(
        size.width * i / (_points - 1),
        size.height * (1.0 - _value(i).clamp(0.0, 1.0)),
      );
      if (i == 0) {
        line.moveTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
      }
    }
    final double endX = size.width * (visible - 1) / (_points - 1);
    final Path fill = Path.from(line)
      ..lineTo(endX, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            this.color.withValues(alpha: 0.28),
            this.color.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = this.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final double endY =
        size.height * (1.0 - _value(visible - 1).clamp(0.0, 1.0));
    canvas.drawCircle(Offset(endX, endY), 3.5, Paint()..color = this.color);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.progress != this.progress ||
      oldDelegate.color != this.color ||
      oldDelegate.grid != this.grid;
}
