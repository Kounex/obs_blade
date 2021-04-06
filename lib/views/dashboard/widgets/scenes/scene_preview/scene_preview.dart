import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import 'preview_warning_dialog.dart';

class ScenePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.watch<DashboardStore>();

    double maxImageHeight = min(
      MediaQuery.of(context).size.height -
          kBottomNavigationBarHeight -
          kToolbarHeight -
          64,
      500,
    );

    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name)
          .listenable(keys: [SettingsKeys.DontShowPreviewWarning.name]),
      builder: (context, Box settingsBox, child) => CustomExpansionTile(
        headerText: 'Current OBS scene preview',
        manualExpand: (expandFunction, expanded) {
          VoidCallback onExpand = () {
            expandFunction();
            dashboardStore.setShouldRequestPreviewImage(
                !dashboardStore.shouldRequestPreviewImage);
          };
          !settingsBox.get(SettingsKeys.DontShowPreviewWarning.name,
                      defaultValue: false) &&
                  !expanded
              ? ModalHandler.showBaseDialog(
                  context: context,
                  dialogWidget: PreviewWarningDialog(
                    onOk: (checked) {
                      settingsBox.put(
                          SettingsKeys.DontShowPreviewWarning.name, checked);
                      onExpand();
                    },
                  ),
                )
              : onExpand();
        },
        expandedBody: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxImageHeight),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Observer(
              builder: (_) => Stack(
                children: [
                  if (dashboardStore.scenePreviewImageBytes != null)
                    Image.memory(
                      dashboardStore.scenePreviewImageBytes!,
                      // height: maxImageHeight,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  if (dashboardStore.scenePreviewImageBytes == null)
                    SizedBox(
                      height: 100.0,
                      child: BaseProgressIndicator(
                        text: 'Fetching preview...',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
