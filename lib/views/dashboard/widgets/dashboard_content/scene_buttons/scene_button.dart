import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/animator/selectable_box.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/shared/network.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/classes/api/scene.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/request_type.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/network_helper.dart';

class SceneButton extends StatelessWidget {
  final Scene scene;
  final bool visible;
  final VoidCallback onVisibilityTap;

  final double height;
  final double width;

  const SceneButton({
    super.key,
    required this.scene,
    required this.visible,
    required this.onVisibilityTap,
    this.height = 100.0,
    this.width = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final AppStatusColors statusColors =
        Theme.of(context).extension<AppStatusColors>()!;

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.ExposeStudioControls],
      builder: (context, settingsBox, child) => Observer(
        builder: (context) {
          final bool studioMode = settingsBox.get(
                  SettingsKeys.ExposeStudioControls.name,
                  defaultValue: false) &&
              dashboardStore.studioMode;

          /// Broadcast tally language for studio mode: the scene currently
          /// on program gets a red PGM tag, the one sitting in preview a
          /// green PVW tag (program wins if both point at the same scene)
          String? tally;
          Color tallyColor = statusColors.live;
          if (studioMode) {
            if (dashboardStore.activeSceneName == this.scene.sceneName) {
              tally = 'PGM';
              tallyColor = statusColors.recording;
            } else if (dashboardStore.studioModePreviewSceneName ==
                this.scene.sceneName) {
              tally = 'PVW';
              tallyColor = statusColors.live;
            }
          }

          return Pressable(
            haptic: true,
            onTap: () {
              if (dashboardStore.editSceneVisibility) {
                this.onVisibilityTap();
              } else {
                if (studioMode) {
                  dashboardStore
                      .setStudioModePreviewSceneName(this.scene.sceneName);
                  NetworkHelper.makeRequest(
                    GetIt.instance<NetworkStore>().activeSession!.socket,
                    RequestType.SetCurrentPreviewScene,
                    {'sceneName': this.scene.sceneName},
                  );
                } else {
                  dashboardStore.setActiveSceneName(this.scene.sceneName);
                  NetworkHelper.makeRequest(
                    GetIt.instance<NetworkStore>().activeSession!.socket,
                    RequestType.SetCurrentProgramScene,
                    {'sceneName': this.scene.sceneName},
                  );
                }
              }
            },
            child: Stack(
              children: [
                SelectableBox(
                  selected:
                      dashboardStore.activeSceneName == this.scene.sceneName,
                  selectedStateBoxBorder: (studioMode
                      ? dashboardStore.studioModePreviewSceneName ==
                          this.scene.sceneName
                      : dashboardStore.activeSceneName == this.scene.sceneName),
                  colorSelected:
                      Theme.of(context).buttonTheme.colorScheme!.secondary,
                  colorUnselected: Theme.of(context).cardColor,
                  boxAnimation: Duration(
                    milliseconds: dashboardStore
                                    .currentTransition?.transitionDuration !=
                                null &&
                            dashboardStore
                                    .currentTransition!.transitionDuration! >=
                                0
                        ? dashboardStore.currentTransition!.transitionDuration!
                        : 0,
                  ),
                  height: this.height,
                  width: this.width,
                  text: this.scene.sceneName,
                ),
                Positioned(
                  left: 6.0,
                  bottom: 6.0,
                  child: AnimatedSwitcher(
                    duration: AppMotion.fast,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        alignment: Alignment.bottomLeft,
                        child: child,
                      ),
                    ),
                    child: tally != null
                        ? _TallyChip(
                            key: ValueKey(tally),
                            label: tally,
                            color: tallyColor,
                          )
                        : const SizedBox(key: ValueKey('no-tally')),
                  ),
                ),
                Positioned(
                  top: 6.0,
                  right: 6.0,
                  child: AnimatedSwitcher(
                    duration: AppMotion.medium,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                    ),
                    child: dashboardStore.editSceneVisibility
                        ? Container(
                            key: const ValueKey('visibility-badge'),
                            height: 28.0,
                            width: 28.0,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .cardColor
                                  .withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: AppMotion.fast,
                              child: Icon(
                                this.visible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                key: ValueKey(this.visible),
                                size: 16.0,
                                color: this.visible
                                    ? null
                                    : statusColors.unreachable,
                              ),
                            ),
                          )
                        : const SizedBox(key: ValueKey('no-badge')),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Small broadcast tally tag (PGM / PVW) rendered on scene buttons while
/// studio mode is active
class _TallyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TallyChip({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16.0,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.92),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        this.label,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 9.0,
              color: StylingHelper.surroundingAwareAccent(
                context: context,
                surroundingColor: this.color,
              ),
            ),
      ),
    );
  }
}
