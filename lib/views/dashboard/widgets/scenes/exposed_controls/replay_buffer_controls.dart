import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/network_helper.dart';
import '../../../../../utils/overlay_handler.dart';

class ReplayBufferControls extends StatelessWidget {
  const ReplayBufferControls({Key? key}) : super(key: key);

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
                onPressed: () {
                  if (dashboardStore.isReplayBufferActive) {
                    OverlayHandler.showStatusOverlay(
                      showDuration: const Duration(seconds: 10),
                      context: context,
                      content: BaseProgressIndicator(
                        text: 'Stopping Replay Buffer...',
                      ),
                    );
                  }
                  NetworkHelper.makeRequest(
                    GetIt.instance<NetworkStore>().activeSession!.socket,
                    RequestType.ToggleReplayBuffer,
                  );
                },
                icon: Icon(
                  dashboardStore.isReplayBufferActive
                      ? CupertinoIcons.stop
                      : CupertinoIcons.reply_thick_solid,
                ),
                color: dashboardStore.isReplayBufferActive
                    ? CupertinoColors.destructiveRed
                    : CupertinoColors.activeGreen,
                text: dashboardStore.isReplayBufferActive ? 'Stop' : 'Start',
              ),
            ),
            const SizedBox(width: 12.0),
            SizedBox(
              width: 128.0,
              child: BaseButton(
                onPressed: dashboardStore.isReplayBufferActive
                    ? () => NetworkHelper.makeRequest(
                        GetIt.instance<NetworkStore>().activeSession!.socket,
                        RequestType.SaveReplayBuffer)
                    : null,
                icon: const Icon(CupertinoIcons.arrow_down_doc_fill),
                color: CupertinoColors.activeOrange,
                text: 'Save',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
