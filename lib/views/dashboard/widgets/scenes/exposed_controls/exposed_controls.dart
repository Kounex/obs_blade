import 'package:flutter/widgets.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'recording_controls.dart';
import 'streaming_controls.dart';

class ExposedControls extends StatelessWidget {
  const ExposedControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ExposeRecordingControls,
        SettingsKeys.ExposeStreamingControls,
      ],
      builder: (context, settingsBox, child) {
        List<Widget> exposedControls = [];

        if (settingsBox.get(SettingsKeys.ExposeStreamingControls.name,
            defaultValue: false)) {
          exposedControls.add(const StreamingControls());
        }

        if (settingsBox.get(SettingsKeys.ExposeRecordingControls.name,
            defaultValue: false)) {
          exposedControls.add(const RecordingControls());
        }

        exposedControls = List.from(exposedControls
            .expand((control) => [control, const SizedBox(height: 12.0)]));

        if (exposedControls.isNotEmpty) {
          exposedControls.insert(0, const SizedBox(height: 24.0));
          exposedControls.removeLast();
        }

        return Column(
          children: exposedControls,
        );
      },
    );
  }
}
