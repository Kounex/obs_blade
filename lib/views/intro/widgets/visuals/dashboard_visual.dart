import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../dashboard/widgets/status_app_bar/on_air_status_cluster.dart';
import '../intro_page.dart';
import 'mock_kit.dart';

/// Dashboard mockup: a device showing the live dashboard - LIVE / REC
/// pills with running timers, the program monitor, scene tiles being
/// tapped and switched, moving audio meters. Midway the device turns from
/// a phone into a tablet and the dashboard recomposes side by side
class DashboardVisual extends IntroVisual {
  const DashboardVisual({super.key, required super.active});

  @override
  State<DashboardVisual> createState() => _DashboardVisualState();
}

class _DashboardVisualState extends IntroLoopState<DashboardVisual> {
  /// Native (unscaled) content sizes of both layouts - the device frame
  /// lerps between them and scales the content to fit
  static const Size _phoneContent = Size(280.0, 548.0);
  static const Size _tabletContent = Size(660.0, 420.0);

  static const Size _phoneFrame = Size(214.0, 414.0);
  static const Size _tabletFrame = Size(400.0, 256.0);

  static const List<String> _scenes = ['Gameplay', 'Just Chatting', 'BRB'];

  /// Program scene per fifth of the loop
  static const List<int> _sceneTimeline = [0, 1, 1, 2, 0];

  final Stopwatch _clock = Stopwatch()..start();

  @override
  Duration get period => const Duration(seconds: 14);

  @override
  double get restValue => 0.1;

  int get _program => _sceneTimeline[(loop.value * 5).floor().clamp(0, 4)];

  /// Press bump (0..1) on the tile about to become program - peaks right
  /// before each switch
  double _press(int scene) {
    final double t = loop.value * 5;
    final int next = (t.floor() + 1) % 5;
    final double into = t - t.floor();
    if (_sceneTimeline[next] != scene ||
        _sceneTimeline[next] == _sceneTimeline[t.floor() % 5]) {
      return 0.0;
    }
    if (into < 0.82) return 0.0;
    return Curves.easeInOut.transform(((into - 0.82) / 0.18).clamp(0.0, 1.0));
  }

  String _timer(int baseSeconds) {
    final int seconds = baseSeconds + _clock.elapsed.inSeconds;
    final int h = seconds ~/ 3600;
    final String m = ((seconds ~/ 60) % 60).toString().padLeft(2, '0');
    final String s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420.0,
      height: 440.0,
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, _) {
          /// 0 = phone, 1 = tablet: morph in at ~40 %, back out at the end
          final double morph = window(0.38, 0.48) * (1.0 - window(0.9, 1.0));
          final Size frame = Size.lerp(_phoneFrame, _tabletFrame, morph)!;

          return Center(
            child: _DeviceFrame(
              size: frame,
              radius: lerpDouble(24.0, 18.0, morph)!,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (morph < 1.0)
                    Opacity(
                      opacity: (1.0 - morph * 2).clamp(0.0, 1.0),
                      child: FittedBox(
                        child: SizedBox.fromSize(
                          size: _phoneContent,
                          child: _phoneLayout(context),
                        ),
                      ),
                    ),
                  if (morph > 0.0)
                    Opacity(
                      opacity: (morph * 2 - 1).clamp(0.0, 1.0),
                      child: FittedBox(
                        child: SizedBox.fromSize(
                          size: _tabletContent,
                          child: _tabletLayout(context),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _pills(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnAirPill(
            label: 'LIVE',
            active: true,
            activeColor: statusColors.live,
            timerText: _timer(1 * 3600 + 24 * 60 + 7),
          ),
          const SizedBox(width: AppSpacing.sm),
          OnAirPill(
            label: 'REC',
            active: true,
            activeColor: statusColors.recording,
            activeTextColor: statusColors.recordingText,
            timerText: _timer(38 * 60 + 52),
          ),
        ],
      ),
    );
  }

  Widget _tile(String name, int index, {required double width}) {
    return Transform.scale(
      scale: 1.0 - _press(index) * 0.06,
      child: MockSceneTile(
        name: name,
        program: _program == index,
        width: width,
        height: 60.0,
      ),
    );
  }

  List<Widget> _audioRows({required int count}) {
    const List<String> names = ['Desktop Audio', 'Mic/Aux', 'Music', 'Alerts'];
    final double t = loop.value;
    return [
      for (int i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        MockAudioRow(
          name: names[i],
          muted: i == 2,
          level: i == 2
              ? 0.4
              : mockLevel(t, i, base: i == 1 ? 0.62 : 0.5, cycles: 28),
        ),
      ],
    ];
  }

  Widget _phoneLayout(BuildContext context) {
    const double width = 280.0 - 2 * AppSpacing.md;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pills(context),
          const SizedBox(height: AppSpacing.lg),
          MockProgramMonitor(
            scene: _program,
            width: width,
            height: width * 9 / 16,
          ),
          const SizedBox(height: AppSpacing.lg),
          const MockCaption('Scenes'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < _scenes.length; i++)
                _tile(_scenes[i], i, width: (width - 2 * AppSpacing.sm) / 3),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const MockCaption('Audio'),
          const SizedBox(height: AppSpacing.sm),
          MockCard(child: Column(children: _audioRows(count: 4))),
        ],
      ),
    );
  }

  Widget _tabletLayout(BuildContext context) {
    const double leftWidth = 390.0;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _pills(context),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: leftWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MockProgramMonitor(
                        scene: _program,
                        width: leftWidth,
                        height: leftWidth * 9 / 16,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (int i = 0; i < _scenes.length; i++)
                            _tile(
                              _scenes[i],
                              i,
                              width: (leftWidth - 2 * AppSpacing.sm) / 3,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const MockCaption('Audio'),
                      const SizedBox(height: AppSpacing.sm),
                      MockCard(child: Column(children: _audioRows(count: 4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Device silhouette: background-colored screen inside a thin bezel
class _DeviceFrame extends StatelessWidget {
  final Size size;
  final double radius;
  final Widget child;

  const _DeviceFrame({
    required this.size,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: this.size.width,
      height: this.size.height,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A2A2E) : const Color(0xFFD9D9DE),
        borderRadius: BorderRadius.circular(this.radius + 4.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
            blurRadius: 24.0,
            offset: const Offset(0.0, 10.0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(this.radius),
        child: ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: this.child,
        ),
      ),
    );
  }
}
