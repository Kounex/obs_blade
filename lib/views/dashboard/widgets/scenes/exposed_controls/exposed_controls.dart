import 'package:flutter/widgets.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'recording_controls.dart';
import 'streaming_controls.dart';

class ExposedControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: [
        SettingsKeys.ExposeRecordingControls,
        SettingsKeys.ExposeStreamingControls,
      ],
      builder: (context, settingsBox, child) {
        List<Widget> exposedControls = [];

        if (settingsBox.get(SettingsKeys.ExposeStreamingControls.name,
            defaultValue: false)) exposedControls.add(StreamingControls());

        if (settingsBox.get(SettingsKeys.ExposeRecordingControls.name,
            defaultValue: false)) exposedControls.add(RecordingControls());

        exposedControls = List.from(exposedControls
            .expand((control) => [control, SizedBox(height: 12.0)]));

        if (exposedControls.isNotEmpty) {
          exposedControls.insert(0, SizedBox(height: 24.0));
          exposedControls.removeLast();
        }

        return Column(
          children: exposedControls,
        );
      },
    );
  }
}
