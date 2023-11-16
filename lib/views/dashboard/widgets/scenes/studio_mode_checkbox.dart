import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/base/checkbox.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';

class StudioModeCheckbox extends StatelessWidget {
  const StudioModeCheckbox({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.ExposeStudioControls,
      ],
      builder: (context, settingsBox, child) {
        return settingsBox.get(SettingsKeys.ExposeStudioControls.name,
                defaultValue: false)
            ? Observer(
                builder: (context) {
                  return BaseCheckbox(
                    value: dashboardStore.studioMode,
                    text: 'Studio Mode',
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (studioMode) => NetworkHelper.makeRequest(
                      GetIt.instance<NetworkStore>().activeSession!.socket,
                      RequestType.SetStudioModeEnabled,
                      {'studioModeEnabled': studioMode},
                    ),
                  );
                },
              )
            : const SizedBox();
      },
    );
  }
}
