import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/general/base/adaptive_switch.dart';
import '../../../shared/general/hive_builder.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../widgets/action_block.dart/action_block.dart';
import '../widgets/action_block.dart/block_entry.dart';

class DashboardCustomisationView extends StatelessWidget {
  const DashboardCustomisationView({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HiveBuilder<dynamic>(
        hiveKey: HiveKeys.Settings,
        builder: (context, settingsBox, child) =>
            TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'Dashboard Customisation',
          listViewChildren: [
            ActionBlock(
              dense: true,
              blockEntries: [
                BlockEntry(
                  leading: CupertinoIcons.profile_circled,
                  leadingSize: 30.0,
                  title: 'Profiles',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeProfile.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeProfile) {
                      settingsBox.put(
                        SettingsKeys.ExposeProfile.name,
                        exposeProfile,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: CupertinoIcons.collections_solid,
                  leadingSize: 26.0,
                  title: 'Scene Collections',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeSceneCollection.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeSceneCollection) {
                      settingsBox.put(
                        SettingsKeys.ExposeSceneCollection.name,
                        exposeSceneCollection,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: Icons.live_tv_rounded,
                  leadingSize: 28.0,
                  title: 'Streaming Controls',
                  help:
                      'If active, the streaming actions (start/stop) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible.',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeStreamingControls.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeStreamingControls) {
                      settingsBox.put(
                        SettingsKeys.ExposeStreamingControls.name,
                        exposeStreamingControls,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: CupertinoIcons.recordingtape,
                  leadingSize: 30.0,
                  title: 'Recording Controls',
                  help:
                      'If active, the recording actions (start/stop/pause) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible.',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeRecordingControls.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeRecordingControls) {
                      settingsBox.put(
                        SettingsKeys.ExposeRecordingControls.name,
                        exposeRecordingControls,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: CupertinoIcons.reply_thick_solid,
                  leadingSize: 28.0,
                  title: 'Replay Controls',
                  help:
                      'If active, the replay buffer actions (start/stop/save) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible.',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeReplayBufferControls.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeReplayBufferControls) {
                      settingsBox.put(
                        SettingsKeys.ExposeReplayBufferControls.name,
                        exposeReplayBufferControls,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: CupertinoIcons.square_grid_3x2_fill,
                  leadingSize: 28.0,
                  title: 'Hotkeys',
                  help:
                      'If active, the hotkey button will be added to the dashboard which enables you to list all available OBS hotkeys and trigger them. Enables more precise interaction with OBS, usually only needed for power users.',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeHotkeys.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeHotkeys) {
                      settingsBox.put(
                        SettingsKeys.ExposeHotkeys.name,
                        exposeHotkeys,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: CupertinoIcons.person_2_square_stack,
                  leadingSize: 30.0,
                  title: 'Scene Preview',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(SettingsKeys.ExposeScenePreview.name,
                        defaultValue: true),
                    onChanged: (exposeScenePreview) {
                      settingsBox.put(
                        SettingsKeys.ExposeScenePreview.name,
                        exposeScenePreview,
                      );
                    },
                  ),
                ),
                BlockEntry(
                  leading: CupertinoIcons.memories,
                  leadingSize: 30.0,
                  title: 'Input Sync',
                  help:
                      'In the advanced settings section for an audio input in OBS, you can adjust "Sync Offset" to align potential delays of other elements with your audio input so they get in sync again.\n\nTurning this on will expose this value for each audio input which also enables it to adjust these in the app.',
                  trailing: BaseAdaptiveSwitch(
                    value: settingsBox.get(
                      SettingsKeys.ExposeInputAudioSyncOffset.name,
                      defaultValue: false,
                    ),
                    onChanged: (exposeInputAudioSyncOffset) {
                      settingsBox.put(
                        SettingsKeys.ExposeInputAudioSyncOffset.name,
                        exposeInputAudioSyncOffset,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
