import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'recording_controls.dart';
import 'streaming_controls.dart';

class ExposedControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name).listenable(keys: [
        SettingsKeys.ExposeRecordingControls.name,
        SettingsKeys.ExposeStreamingControls.name,
      ]),
      builder: (context, Box settingsBox, child) {
        List<Widget> exposedControls = [];

        if (settingsBox.get(SettingsKeys.ExposeStreamingControls.name,
            defaultValue: false)) exposedControls.add(StreamingControls());

        if (settingsBox.get(SettingsKeys.ExposeRecordingControls.name,
            defaultValue: false)) exposedControls.add(RecordingControls());

        exposedControls = List.from(exposedControls
            .expand((control) => [control, SizedBox(height: 12.0)]));

        if (exposedControls.isNotEmpty) exposedControls.removeLast();

        return Column(
          children: exposedControls,
        );
      },
    );
  }
}
