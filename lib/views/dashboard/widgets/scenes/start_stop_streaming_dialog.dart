import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../shared/dialogs/confirmation.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';

class StartStopStreamingDialog extends StatelessWidget {
  final bool isLive;
  final VoidCallback onStreamStartStop;

  const StartStopStreamingDialog({
    Key? key,
    required this.isLive,
    required this.onStreamStartStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: (this.isLive ? 'Stop' : 'Start') + ' Streaming',
      body: this.isLive
          ? 'Are you sure you want to stop the stream? Nothing more to show or talk about? Or just tired or no time?\n\n... just to make sure it\'s intentional!'
          : 'Are you sure you are ready to start the stream? Everything done? Stream title and description updated?\n\nIf yes: let\'s go!',
      isYesDestructive: true,
      enableDontShowAgainOption: true,
      onOk: (checked) {
        Hive.box(HiveKeys.Settings.name).put(
            this.isLive
                ? SettingsKeys.DontShowStreamStopMessage.name
                : SettingsKeys.DontShowStreamStartMessage.name,
            checked);
        this.onStreamStartStop();
      },
    );
  }
}
