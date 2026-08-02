import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';

import '../../../../../shared/general/custom_expansion_tile.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import 'preview_warning_dialog.dart';

/// Hero tag shared between the inline scene preview and its fullscreen
/// route - only one [ScenePreview] is mounted at a time (regular vs.
/// streaming layout), so the tag is unique per HeroController scope
const String kScenePreviewHeroTag = 'scene-preview-hero';

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
            Container(
              width: double.infinity,
              color: Colors.black,
            ),
            AnimatedSwitcher(
              duration: AppMotion.slow,
              child: _imageAvailable
                  ? Hero(
                      tag: kScenePreviewHeroTag,
                      child: Observer(builder: (context) {
                        return Image.memory(
                          dashboardStore.scenePreviewImageBytes!,

                          /// Might reduce the memory used and therefore
                          /// the performance of the frequently changing
                          /// image - a multiplicator is used since
                          /// using the original size would decrease the
                          /// quality significantly
                          // cacheHeight: (maxImageHeight * 1.5).toInt(),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        );
                      }),
                    )
                  : SizedBox(
                      key: const ValueKey('fetching-preview'),
                      height: 150.0,
                      child: BaseProgressIndicator(
                        text: 'Fetching preview...',
                      ),
                    ),
            ),
            if (_imageAvailable)
              AnimatedOpacity(
                duration: AppMotion.medium,
                opacity: _uiVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_uiVisible,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 64.0,
                      alignment: Alignment.bottomRight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: IconButton(
                        onPressed: _uiVisible
                            ? () {
                                _handleImageTap();

                                /// Root navigator so the lightbox covers the
                                /// tab shell (app / tab bar) as well - costs
                                /// the [Hero] flight (different
                                /// [HeroController] scope), accepted tradeoff
                                Navigator.of(context, rootNavigator: true)
                                    .push(
                                  PageRouteBuilder<void>(
                                    opaque: true,
                                    transitionDuration: AppMotion.medium,
                                    reverseTransitionDuration:
                                        AppMotion.medium,
                                    pageBuilder: (context, animation,
                                            secondaryAnimation) =>
                                        const _ScenePreviewFullscreen(),
                                    transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) =>
                                        FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  ),
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
              expandedBody: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: preview,
              ),
            )
          : const SizedBox(),
    );
  }
}

/// Fullscreen variant of the scene preview - pushed on the root navigator so
/// the lightbox covers the whole shell chrome (tab bar included). The [Hero]
/// flight from the inline preview does not survive the navigator switch -
/// the fade transition carries the motion instead. Mirrors the chrome of
/// [ModalHandler.showFullscreen] (black surface + close button).
class _ScenePreviewFullscreen extends StatelessWidget {
  const _ScenePreviewFullscreen();

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Material(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Hero(
            tag: kScenePreviewHeroTag,
            child: Observer(
              builder: (context) => Image.memory(
                dashboardStore.scenePreviewImageBytes!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
          Positioned(
            top: 12.0 + MediaQuery.paddingOf(context).top,
            right: 12.0 + MediaQuery.paddingOf(context).right,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.clear,
                  color: Colors.white,
                  size: 20.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
