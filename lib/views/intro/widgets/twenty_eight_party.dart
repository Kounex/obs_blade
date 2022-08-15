import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('ENJOY'),
        ElevatedButton(
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
          child: const Text('Start'),
        ),
      ],
    );
  }
}
