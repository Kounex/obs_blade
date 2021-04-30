import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/network_helper.dart';
import '../../../services/record_stream.dart';

class RecordingControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: [
        SettingsKeys.DontShowRecordStartMessage,
        SettingsKeys.DontShowRecordStopMessage,
      ],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 128.0,
              child: ElevatedButton.icon(
                onPressed: () => RecordStreamService.triggerRecordStartStop(
                  context,
                  dashboardStore.isRecording,
                  settingsBox.get(SettingsKeys.DontShowRecordStartMessage.name,
                      defaultValue: false),
                  settingsBox.get(SettingsKeys.DontShowRecordStopMessage.name,
                      defaultValue: false),
                ),
                icon: Icon(
                  dashboardStore.isRecording
                      ? CupertinoIcons.stop
                      : CupertinoIcons.recordingtape,
                ),
                style: ElevatedButton.styleFrom(
                  primary: dashboardStore.isRecording
                      ? CupertinoColors.destructiveRed
                      : Colors.green,
                ),
                label: Text(dashboardStore.isRecording ? 'Stop' : 'Start'),
              ),
            ),
            SizedBox(width: 12.0),
            SizedBox(
              width: 128.0,
              child: ElevatedButton.icon(
                onPressed: dashboardStore.isRecording
                    ? () => NetworkHelper.makeRequest(
                          context.read<NetworkStore>().activeSession!.socket,
                          context.read<DashboardStore>().isRecordingPaused
                              ? RequestType.ResumeRecording
                              : RequestType.PauseRecording,
                        )
                    : null,
                icon: Icon(
                  dashboardStore.isRecordingPaused
                      ? CupertinoIcons.play
                      : CupertinoIcons.pause,
                ),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                ),
                label:
                    Text(dashboardStore.isRecordingPaused ? 'Resume' : 'Pause'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
