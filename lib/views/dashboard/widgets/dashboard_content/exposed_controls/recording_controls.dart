import 'package:flutter/cupertino.dart';
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
import 'exposed_controls.dart';

class RecordingControls extends StatelessWidget {
  const RecordingControls({
    super.key,
  });

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
            Expanded(
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

                /// Ghost button (token-delta §2.6): no green/red state fills
                /// - red is reserved for recording/program state (rule 7),
                /// which the REC pill carries
                secondary: true,
                text: dashboardStore.isRecording ? 'Stop' : 'Start',
              ),
            ),
            const SizedBox(width: kExposedControlsSpace),
            Expanded(
              child: BaseButton(
                onPressed: dashboardStore.isRecording
                    ? () => NetworkHelper.makeRequest(
                          GetIt.instance<NetworkStore>().activeSession!.socket,
                          RequestType.ToggleRecordPause,
                        )
                    : null,
                icon: Icon(
                  dashboardStore.isRecordingPaused
                      ? CupertinoIcons.play
                      : CupertinoIcons.pause,
                ),

                /// Ghost button - the hardcoded green/orange state fills
                /// encoded nothing per the color grammar (rules 7+8)
                secondary: true,
                text: dashboardStore.isRecordingPaused ? 'Resume' : 'Pause',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
