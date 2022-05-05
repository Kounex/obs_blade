import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import '../../../../../shared/general/base/button.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../services/record_stream.dart';

class StreamingControls extends StatelessWidget {
  const StreamingControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DontShowStreamStartMessage,
        SettingsKeys.DontShowStreamStopMessage,
      ],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) => SizedBox(
          width: 268.0,
          child: BaseButton(
            onPressed: () => RecordStreamService.triggerStreamStartStop(
              context,
              dashboardStore.isLive,
              settingsBox.get(SettingsKeys.DontShowStreamStartMessage.name,
                  defaultValue: false),
              settingsBox.get(SettingsKeys.DontShowStreamStopMessage.name,
                  defaultValue: false),
            ),
            icon: Transform.translate(
              offset: Offset(0.0, dashboardStore.isLive ? 0.0 : -2.0),
              child: Icon(
                dashboardStore.isLive
                    ? CupertinoIcons.stop
                    : Icons.live_tv_rounded,
              ),
            ),
            color: dashboardStore.isLive
                ? CupertinoColors.destructiveRed
                : Colors.green,
            text: dashboardStore.isLive ? 'Go Offline' : 'Go Live',
          ),
        ),
      ),
    );
  }
}
