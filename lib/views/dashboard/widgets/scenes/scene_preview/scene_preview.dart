import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';

import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import 'preview_warning_dialog.dart';

class ScenePreview extends StatefulWidget {
  final bool expandable;

  const ScenePreview({
    super.key,
    this.expandable = true,
  });

  @override
  State<ScenePreview> createState() => _ScenePreviewState();
}

class _ScenePreviewState extends State<ScenePreview> {
  bool _imageAvailable = false;
  bool _fullscreen = false;
  bool _uiVisible = false;

  Timer? _timer;

  final List<ReactionDisposer> _d = [];

  @override
  void initState() {
    super.initState();

    _d.add(
      reaction<bool>(
        (_) => GetIt.instance<DashboardStore>().scenePreviewImageBytes != null,
        (imageAvailable) => setState(() => _imageAvailable = imageAvailable),
      ),
    );

    if (!this.widget.expandable) {
      Future.delayed(const Duration(milliseconds: 500), () {
        GetIt.instance<DashboardStore>().setShouldRequestPreviewImage(true);
      });
    }
  }

  void _handleImageTap([int msToHide = 3000]) {
    if (!_uiVisible) {
      setState(() => _uiVisible = true);
      _timer = Timer(
        Duration(milliseconds: msToHide),
        () => setState(() => _uiVisible = false),
      );
    } else {
      _timer?.cancel();
      setState(() => _uiVisible = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final d in _d) {
      d();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    final Widget preview = GestureDetector(
      onTap: _imageAvailable
          ? () {
              _handleImageTap();
            }
          : null,
      child: IntrinsicHeight(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_imageAvailable && !_fullscreen)
              Observer(builder: (context) {
                return AnimatedScale(
                  duration: const Duration(milliseconds: 2000),
                  scale: 1.0,
                  alignment: Alignment.topCenter,
                  child: Image.memory(
                    dashboardStore.scenePreviewImageBytes!,

                    /// Might reduce the memory used and therefore
                    /// the performance of the frequently changing
                    /// image - a multiplicator is used since
                    /// using the original size would decrease the
                    /// quality significantly
                    // cacheHeight: (maxImageHeight * 1.5).toInt(),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                );
              }),
            if (_imageAvailable)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _uiVisible ? 1.0 : 0.0,
                child: Container(
                  alignment: Alignment.bottomRight,
                  color: Colors.black87,
                  child: IconButton(
                    onPressed: _uiVisible
                        ? () {
                            setState(() => _fullscreen = true);
                            _handleImageTap();
                            ModalHandler.showFullscreen(
                              context: context,
                              content: Observer(
                                builder: (context) => Image.memory(
                                  dashboardStore.scenePreviewImageBytes!,
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ).then(
                              (_) => setState(() => _fullscreen = false),
                            );
                          }
                        : null,
                    icon: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        CupertinoIcons.fullscreen,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (!_imageAvailable)
              SizedBox(
                height: 150.0,
                child: BaseProgressIndicator(
                  text: 'Fetching preview...',
                ),
              ),
          ],
        ),
      ),
    );

    if (!this.widget.expandable) {
      return preview;
    }

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [
        SettingsKeys.DontShowPreviewWarning,
        SettingsKeys.ExposeScenePreview,
      ],
      builder: (context, settingsBox, child) => settingsBox
              .get(SettingsKeys.ExposeScenePreview.name, defaultValue: true)
          ? CustomExpansionTile(
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
              expandedBody: preview,
            )
          : const SizedBox(),
    );
  }
}
