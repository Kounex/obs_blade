import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/chat_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/profiles_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/scene_audio_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/scene_buttons_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/scene_items_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/scene_preview_mock.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/stats_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/studio_mode_config_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/studio_mode_transition_preview.dart';

import '../../../../../models/enums/dashboard_element.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'controls_preview.dart';
import 'element_body.dart';
import 'mock_parts.dart';

class PreviewConfig {
  final DashboardElement element;
  final Widget widget;
  final bool canBeNotVisible;
  final bool visible;

  PreviewConfig({
    required this.element,
    required this.widget,
    required this.canBeNotVisible,
    required this.visible,
  });
}

class ElementList extends StatelessWidget {
  const ElementList({super.key});

  List<PreviewConfig> _previewConfigs() => [
        PreviewConfig(
          element: DashboardElement.ExposedProfile,
          widget: const ProfilesPreview(),
          canBeNotVisible: true,
          visible: Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeProfile.name,
                defaultValue: false,
              ) ||
              Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeSceneCollection.name,
                defaultValue: false,
              ),
        ),
        PreviewConfig(
          element: DashboardElement.ExposedControls,
          widget: const ControlsPreview(),
          canBeNotVisible: true,
          visible: Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeStreamingControls.name,
                defaultValue: false,
              ) ||
              Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeRecordingControls.name,
                defaultValue: false,
              ) ||
              Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeReplayBufferControls.name,
                defaultValue: false,
              ) ||
              Hive.box(HiveKeys.Settings.name).get(
                SettingsKeys.ExposeHotkeys.name,
                defaultValue: false,
              ),
        ),
        PreviewConfig(
          element: DashboardElement.SceneButtons,
          widget: const SceneButtonsPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.StudioModeTransition,
          widget: const StudioModeTransitionPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.StudioModeConfig,
          widget: const StudioModeConfigPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.ScenePreview,
          widget: const ScenePreviewMock(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.SceneItems,
          widget: const SceneItemsPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.SceneItemsAudio,
          widget: const SceneAudioPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.StreamChat,
          widget: const ChatPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.OBSStats,
          widget: const StatsPreview(),
          canBeNotVisible: false,
          visible: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final List<PreviewConfig> config = _previewConfigs();

    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      builder: (context, settingsBox, child) {
        List<DashboardElement> elements = [
          ...settingsBox.get(SettingsKeys.DashboardElementsOrder.name,
              defaultValue: DashboardElement.values)
        ];
        return ReorderableListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.only(
            top: 18.0,
            bottom: kBottomNavigationBarHeight,
          ),
          buildDefaultDragHandles: false,
          itemCount: elements.length,
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              /// Spring-ish lift: slight overshoot while picking up, settling
              /// into a scaled, elevated card while dragging
              final double springValue =
                  AppMotion.spring.transform(animation.value);
              final double elevation =
                  lerpDouble(0, 8, clampDouble(springValue, 0.0, 1.0))!;
              return Transform.scale(
                scale: 1.0 + 0.02 * springValue,
                child: Material(
                  elevation: elevation,
                  type: MaterialType.transparency,
                  child: child,
                ),
              );
            },
            child: child,
          ),
          onReorderStart: (_) => HapticFeedback.lightImpact(),
          itemBuilder: (context, index) => ElementBody(
            key: ValueKey(elements[index]),
            index: index,
            config: config.firstWhere(
              (config) => config.element == elements[index],
              orElse: () => PreviewConfig(
                element: elements[index],
                widget: const GenericMockPreview(),
                canBeNotVisible: false,
                visible: true,
              ),
            ),
          ),
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            elements.insert(newIndex, elements.removeAt(oldIndex));
            settingsBox.put(SettingsKeys.DashboardElementsOrder.name, elements);
          },
        );
      },
    );
  }
}
