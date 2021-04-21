import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../services/record_stream.dart';

class StreamingControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();

    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name).listenable(keys: [
        SettingsKeys.DontShowStreamStartMessage.name,
        SettingsKeys.DontShowStreamStopMessage.name,
      ]),
      builder: (context, Box settingsBox, child) => Observer(
        builder: (context) => SizedBox(
          width: 268.0,
          child: ElevatedButton.icon(
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
            style: ElevatedButton.styleFrom(
              primary: dashboardStore.isLive
                  ? CupertinoColors.destructiveRed
                  : Colors.green,
            ),
            label: Text(dashboardStore.isLive ? 'Go Offline' : 'Go Live'),
          ),
        ),
      ),
    );
  }
}
