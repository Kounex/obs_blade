import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/dropdown.dart';

import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../utils/network_helper.dart';

class ProfileControl extends StatelessWidget {
  const ProfileControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (context) {
        return BaseDropdown<String>(
          value: dashboardStore.profiles != null &&
                  dashboardStore.profiles!
                      .contains(dashboardStore.currentProfileName)
              ? dashboardStore.currentProfileName
              : null,
          items: dashboardStore.profiles
                  ?.map(
                    (profileName) => BaseDropdownItem(
                      value: profileName,
                      text: profileName,
                    ),
                  )
                  .toList() ??
              [],
          label: 'Profile',
          onChanged: (profileName) {
            if (profileName != dashboardStore.currentProfileName) {
              NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.SetCurrentProfile,
                {'profileName': profileName},
              );
            }
          },
        );
      },
    );
  }
}
