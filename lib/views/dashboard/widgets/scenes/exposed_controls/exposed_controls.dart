import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/card.dart';
import 'package:obs_blade/shared/general/described_box.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/exposed_controls/replay_buffer_controls.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'recording_controls.dart';
import 'streaming_controls.dart';

const double kExposedButtonsMaxWidth = 92.0;
const double kExposedControlsSpace = 12.0;

class ExposedControls extends StatelessWidget {
  const ExposedControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ExposeRecordingControls,
        SettingsKeys.ExposeStreamingControls,
        SettingsKeys.ExposeReplayBufferControls,
      ],
      builder: (context, settingsBox, child) {
        List<Widget> exposedControls = [];

        if (settingsBox.get(SettingsKeys.ExposeStreamingControls.name,
            defaultValue: false)) {
          exposedControls.add(
            DescribedBox(
              label: 'Stream',
              borderColor: Theme.of(context).dividerColor,
              child: const Center(
                child: StreamingControls(),
              ),
            ),
          );
        }

        if (settingsBox.get(SettingsKeys.ExposeRecordingControls.name,
            defaultValue: false)) {
          exposedControls.add(
            DescribedBox(
              label: 'Recording',
              borderColor: Theme.of(context).dividerColor,
              child: const RecordingControls(),
            ),
          );
        }

        if (settingsBox.get(SettingsKeys.ExposeReplayBufferControls.name,
            defaultValue: false)) {
          exposedControls.add(
            DescribedBox(
              label: 'Replay Buffer',
              borderColor: Theme.of(context).dividerColor,
              child: const ReplayBufferControls(),
            ),
          );
        }

        exposedControls = List.from(
          exposedControls.expand(
            (control) => [
              control,
              const SizedBox(height: 18.0),
            ],
          ),
        );

        if (exposedControls.isNotEmpty) {
          exposedControls.removeLast();
        }

        return exposedControls.isNotEmpty
            ? BaseCard(
                child: Column(
                  children: exposedControls,
                ),
              )
            : const SizedBox();
      },
    );
  }
}
