import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/general/hive_builder.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/network_helper.dart';

class ProfileControl extends StatelessWidget {
  const ProfileControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeProfile],
      builder: (context, settingsBox, child) => settingsBox.get(
        SettingsKeys.ExposeProfile.name,
        defaultValue: true,
      )
          ? LayoutBuilder(builder: (context, constraints) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: Theme.of(context).textTheme.caption,
                    ),
                    Observer(
                      builder: (_) => DropdownButton<String>(
                        value: dashboardStore.profiles != null &&
                                dashboardStore.profiles!
                                    .contains(dashboardStore.currentProfileName)
                            ? dashboardStore.currentProfileName
                            : null,
                        isDense: true,
                        onChanged: (profileName) {
                          if (profileName !=
                              dashboardStore.currentProfileName) {
                            NetworkHelper.makeRequest(
                              GetIt.instance<NetworkStore>()
                                  .activeSession!
                                  .socket,
                              RequestType.SetCurrentProfile,
                              {'profileName': profileName},
                            );
                          }
                        },
                        items: dashboardStore.profiles
                                ?.map(
                                  (profileName) => DropdownMenuItem(
                                    value: profileName,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 72,
                                        maxWidth: constraints.maxWidth - 24,
                                      ),
                                      child: Text(
                                        profileName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                )
                                .toList() ??
                            [],
                      ),
                    ),
                  ],
                ),
              );
            })
          : Container(),
    );
  }
}
