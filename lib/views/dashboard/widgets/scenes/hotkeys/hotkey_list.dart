import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/overlay/base_progress_indicator.dart';
import 'package:obs_blade/stores/views/dashboard.dart';

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hotkeys',
                  style: Theme.of(context).textTheme.headline5,
                ),
                const SizedBox(height: 6.0),
                const BaseDivider(),
                Expanded(
                  child: Observer(
                    builder: (context) => dashboardStore.hotkeys == null
                        ? BaseProgressIndicator(
                            text: 'Fetching...',
                          )
                        : SingleChildScrollView(
                            controller: this.controller,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Wrap(
                                children: dashboardStore.hotkeys!
                                    .map(
                                      (hotkey) => Text(hotkey),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
