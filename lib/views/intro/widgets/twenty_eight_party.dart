import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';

import '../../../shared/general/base/divider.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../../../utils/routing_helper.dart';
import '../intro.dart';
import 'intro_primary_button.dart';

class TwentyEightParty extends StatefulWidget {
  final bool manually;

  const TwentyEightParty({
    super.key,
    required this.manually,
  });

  @override
  State<TwentyEightParty> createState() => _TwentyEightPartyState();
}

class _TwentyEightPartyState extends State<TwentyEightParty> {
  /// Multi-burst celebration: one explosive center cannon plus two angled
  /// side cannons, fired in sequence (short emission duration per burst -
  /// the emission frequency is 1.0, so particles pump out every frame)
  final List<ConfettiController> _controllers = List.generate(
    3,
    (_) => ConfettiController(duration: AppMotion.instant),
  );

  final List<Timer> _burstTimers = [];

  @override
  void initState() {
    super.initState();

    int burstIndex = 0;
    for (final Duration delay
        in [AppMotion.slow, AppMotion.dramatic, AppMotion.dramatic * 1.5]) {
      final int index = burstIndex++;
      _burstTimers.add(
        Timer(delay, () {
          if (this.mounted) {
            _controllers[index].play();
          }
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final Timer timer in _burstTimers) {
      timer.cancel();
    }
    for (final ConfettiController controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> confettiColors = [
      Theme.of(context).buttonTheme.colorScheme!.secondary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).extension<AppStatusColors>()!.live,
    ];

    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topCenter,
      children: [
        BaseConstrainedBox(
          hasBasePadding: true,
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StaggeredEntrance(
                      index: 0,
                      child: AnimatedResultIcon(
                        type: AnimatedResultType.positive,
                        size: 72.0,
                        color: Theme.of(context)
                            .extension<AppStatusColors>()!
                            .live,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    StaggeredEntrance(
                      index: 1,
                      child: Column(
                        children: [
                          Text(
                            'Congrats!',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'You are ready to go - since OBS 28.X the WebSocket plugin got merged into OBS, which means it\'s already part of your instance and can be used out of the box!\n\nIsn\'t this great?!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// Bottom-anchored CTA cluster - same anchoring as the intro
              /// slides' control row (safe area + base padding)
              StaggeredEntrance(
                index: 2,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom +
                        kIntroControlsBottomPadding,
                  ),
                  child: Column(
                    children: [
                      const BaseDivider(),
                      const SizedBox(height: AppSpacing.lg),
                      IntroPrimaryButton(
                        onPressed: () {
                          Hive.box(HiveKeys.Settings.name).put(
                            SettingsKeys.HasUserSeenIntro202208.name,
                            true,
                          );
                          Navigator.of(context).pushReplacementNamed(
                            this.widget.manually
                                ? SettingsTabRoutingKeys.Landing.route
                                : AppRoutingKeys.Tabs.route,
                          );
                        },
                        text: 'Start',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Center cannon - explosive blast straight down
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _controllers[0],
            colors: confettiColors,
            gravity: 0.075,
            blastDirection: pi / 2,
            emissionFrequency: 1.0,
            numberOfParticles: 18,
            blastDirectionality: BlastDirectionality.explosive,
          ),
        ),

        /// Left cannon - angled across the screen
        Positioned(
          top: 0,
          left: 0,
          child: ConfettiWidget(
            confettiController: _controllers[1],
            colors: confettiColors,
            gravity: 0.075,
            blastDirection: pi / 3,
            emissionFrequency: 1.0,
            numberOfParticles: 12,
            blastDirectionality: BlastDirectionality.directional,
          ),
        ),

        /// Right cannon - angled across the screen
        Positioned(
          top: 0,
          right: 0,
          child: ConfettiWidget(
            confettiController: _controllers[2],
            colors: confettiColors,
            gravity: 0.075,
            blastDirection: 2 * pi / 3,
            emissionFrequency: 1.0,
            numberOfParticles: 12,
            blastDirectionality: BlastDirectionality.directional,
          ),
        ),
      ],
    );
  }
}
