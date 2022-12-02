import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../../../../../shared/general/base/divider.dart';

class HotkeyList extends StatelessWidget {
  final ScrollController? controller;

  const HotkeyList({
    super.key,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(right: 4.0),
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(CupertinoIcons.clear_circled_solid),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotkeys',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    const SizedBox(height: 6.0),
                    const Text(
                        'Only these internal names are exposed by the WebSocket API, so a bit of guessing and try and error is necessary to find the correct ones. Users have also reported that some hotkeys do not work at all via the WebSocket API, so expect problems when using this feature.'),
                    const SizedBox(height: 8.0),
                    const BaseDivider(),
                  ],
                ),
              ),
              Expanded(
                child: Observer(
                  builder: (context) => dashboardStore.hotkeys == null
                      ? BaseProgressIndicator(
                          text: 'Fetching...',
                        )
                      : Scrollbar(
                          controller: this.controller,
                          child: ListView.separated(
                            controller: this.controller,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0) +
                                    EdgeInsets.only(
                                        bottom: MediaQuery.of(context)
                                                .padding
                                                .bottom +
                                            12.0),
                            itemCount: dashboardStore.hotkeys!.length,
                            separatorBuilder: (context, index) =>
                                const BaseDivider(),
                            itemBuilder: (context, index) => ListTile(
                              title: Text(
                                dashboardStore.hotkeys![index]
                                    .split('.')
                                    .sublist(1)
                                    .join(),
                              ),
                              subtitle: Text(dashboardStore.hotkeys![index]),
                              contentPadding: const EdgeInsets.all(0),
                              trailing: BaseButton(
                                text: 'Trigger',
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Future.delayed(
                                    const Duration(milliseconds: 500),
                                    () {
                                      NetworkHelper.makeRequest(
                                        GetIt.instance<NetworkStore>()
                                            .activeSession!
                                            .socket,
                                        RequestType.TriggerHotkeyByName,
                                        {
                                          'hotkeyName':
                                              dashboardStore.hotkeys![index]
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
