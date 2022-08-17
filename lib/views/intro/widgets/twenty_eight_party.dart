import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/general/base/constrained_box.dart';
import 'package:obs_blade/shared/general/themed/cupertino_button.dart';

import '../../../shared/general/base/divider.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../../../utils/routing_helper.dart';

class TwentyEightParty extends StatelessWidget {
  final bool manually;

  const TwentyEightParty({
    super.key,
    required this.manually,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topCenter,
      children: [
        BaseConstrainedBox(
          hasBasePadding: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Congrats!\n\nYou are ready to go - since OBS 28.X the WebSocket plugin got merged into OBS, which means it\'s already part of your instance and can be used out of the box!\n\nIsn\'t this great?!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 48.0),
              const BaseDivider(),
              ThemedCupertinoButton(
                onPressed: () {
                  Hive.box(HiveKeys.Settings.name).put(
                    SettingsKeys.HasUserSeenIntro202208.name,
                    true,
                  );
                  Navigator.of(context).pushReplacementNamed(
                    this.manually
                        ? SettingsTabRoutingKeys.Landing.route
                        : AppRoutingKeys.Tabs.route,
                  );
                },
                text: 'Start',
              ),
            ],
          ),
        ),
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController:
                ConfettiController(duration: const Duration(milliseconds: 1000))
                  ..play(),
            // maximumSize: const Size(20, 20),
            // minimumSize: const Size(16, 16),
            // createParticlePath: (size) => Path()
            //   ..addOval(Rect.fromCircle(
            //       center: Offset(size.width / 2, size.height / 2),
            //       radius: size.width / 2)),
            blastDirection: pi / 2,
            emissionFrequency: 0.5,
            numberOfParticles: 10,
            blastDirectionality: BlastDirectionality.explosive,
          ),
        ),
      ],
    );
  }
}
