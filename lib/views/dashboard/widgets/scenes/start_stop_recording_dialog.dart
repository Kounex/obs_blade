import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../shared/dialogs/confirmation.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';

class StartStopRecordingDialog extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onRecordStartStop;

  StartStopRecordingDialog({
    required this.isRecording,
    required this.onRecordStartStop,
  });

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
        title: (this.isRecording ? 'Stop' : 'Start') + ' Recording',
        body: this.isRecording
            ? 'Do you want to stop recording? Got everything on tape as intended?\n\nIf yes: nice work!'
            : 'Do you want to start recording? Recording unintentionally is not as bad as suddenly starting to stream!\n\nStill asking just to be sure!',
        isYesDestructive: true,
        enableDontShowAgainOption: true,
        onOk: (checked) {
          Hive.box(HiveKeys.Settings.name).put(
              this.isRecording
                  ? SettingsKeys.DontShowRecordStopMessage.name
                  : SettingsKeys.DontShowRecordStartMessage.name,
              checked);
          this.onRecordStartStop();
        });
  }
}
