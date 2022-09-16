import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import 'preview_warning_dialog.dart';

class ScenePreview extends StatelessWidget {
  const ScenePreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    double maxImageHeight = min(
      MediaQuery.of(context).size.height -
          kBottomNavigationBarHeight -
          kToolbarHeight -
          64,
      500,
    );

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DontShowPreviewWarning,
        SettingsKeys.ExposeScenePreview,
      ],
      builder: (context, settingsBox, child) => settingsBox
              .get(SettingsKeys.ExposeScenePreview.name, defaultValue: true)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: CustomExpansionTile(
                headerText: 'Current OBS scene preview',
                manualExpand: (expandFunction, expanded) {
                  // ignore: prefer_function_declarations_over_variables
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
                                  SettingsKeys.DontShowPreviewWarning.name,
                                  checked);
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
                              // cacheHeight: (maxImageHeight * 1.5).toInt(),
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
            )
          : Container(),
    );
  }
}
