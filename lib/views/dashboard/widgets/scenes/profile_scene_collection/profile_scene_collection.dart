import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/card.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'profile_control.dart';
import 'scene_collection_control.dart';

class ProfileSceneCollection extends StatelessWidget {
  const ProfileSceneCollection({super.key});

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ExposeProfile,
        SettingsKeys.ExposeSceneCollection,
      ],
      builder: (context, settingsBox, child) => settingsBox
                  .get(SettingsKeys.ExposeProfile.name, defaultValue: false) ||
              settingsBox.get(SettingsKeys.ExposeSceneCollection.name,
                  defaultValue: false)
          ? BaseCard(
              bottomPadding: 0,
              child: Row(
                children: [
                  if (settingsBox.get(SettingsKeys.ExposeProfile.name,
                      defaultValue: false)) ...[
                    const Expanded(
                      child: ProfileControl(),
                    ),
                    const SizedBox(width: 24.0),
                  ],
                  Expanded(
                    child: settingsBox.get(
                            SettingsKeys.ExposeSceneCollection.name,
                            defaultValue: false)
                        ? const SceneCollectionControl()
                        : const SizedBox(),
                  ),
                ],
              ),
            )
          : const SizedBox(),
    );
  }
}
