import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/network_helper.dart';
import '../../../services/record_stream.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DontShowRecordStartMessage,
        SettingsKeys.DontShowRecordStopMessage,
      ],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 128.0,
              child: BaseButton(
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
                color: dashboardStore.isRecording
                    ? CupertinoColors.destructiveRed
                    : Colors.green,
                text: dashboardStore.isRecording ? 'Stop' : 'Start',
              ),
            ),
            const SizedBox(width: 12.0),
            SizedBox(
              width: 128.0,
              child: BaseButton(
                onPressed: dashboardStore.isRecording
                    ? () => NetworkHelper.makeRequest(
                          GetIt.instance<NetworkStore>().activeSession!.socket,
                          GetIt.instance<DashboardStore>().isRecordingPaused
                              ? RequestType.ResumeRecord
                              : RequestType.PauseRecord,
                        )
                    : null,
                icon: Icon(
                  dashboardStore.isRecordingPaused
                      ? CupertinoIcons.play
                      : CupertinoIcons.pause,
                ),
                color: Colors.orange,
                text: dashboardStore.isRecordingPaused ? 'Resume' : 'Pause',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
