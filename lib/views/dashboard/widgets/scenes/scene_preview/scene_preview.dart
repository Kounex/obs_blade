import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/fader.dart';
import 'package:obs_blade/shared/general/themed/cupertino_button.dart';

import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import 'preview_warning_dialog.dart';

class ScenePreview extends StatefulWidget {
  const ScenePreview({Key? key}) : super(key: key);

  @override
  State<ScenePreview> createState() => _ScenePreviewState();
}

class _ScenePreviewState extends State<ScenePreview> {
  bool _fullscreen = false;

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
                  /// + X is the puffer used for the elements beside the scene
                  /// preview - currently the maximize button so the height
                  /// constraint is not set for the whole expandable but for the
                  /// actual preview size
                  constraints: BoxConstraints(maxHeight: maxImageHeight + 64),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Observer(
                      builder: (_) => Stack(
                        children: [
                          if (dashboardStore.scenePreviewImageBytes != null)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_fullscreen)
                                  Flexible(
                                    child: Image.memory(
                                      dashboardStore.scenePreviewImageBytes!,
                                      // height: maxImageHeight,

                                      /// Might reduce the memory used and therefore
                                      /// the performance of the frequently changing
                                      /// image - a multiplicator is used since
                                      /// using the original size would decrease the
                                      /// quality significantly
                                      // cacheHeight: (maxImageHeight * 1.5).toInt(),
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                                const SizedBox(height: 12.0),
                                ThemedCupertinoButton(
                                  text: 'Maximize',
                                  padding: const EdgeInsets.all(0),
                                  onPressed: () {
                                    setState(() => _fullscreen = true);
                                    ModalHandler.showFullscreen(
                                      context: context,
                                      content: Fader(
                                        child: Observer(
                                          builder: (context) => Image.memory(
                                            dashboardStore
                                                .scenePreviewImageBytes!,
                                            fit: BoxFit.contain,
                                            gaplessPlayback: true,
                                          ),
                                        ),
                                      ),
                                    ).then(
                                      (_) =>
                                          setState(() => _fullscreen = false),
                                    );
                                  },
                                ),
                              ],
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
