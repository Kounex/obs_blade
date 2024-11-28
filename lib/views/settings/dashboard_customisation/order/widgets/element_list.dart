import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/profiles_preview.dart';
import 'package:obs_blade/views/settings/dashboard_customisation/order/widgets/scene_buttons_preview.dart';

import '../../../../../models/enums/dashboard_element.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'controls_preview.dart';
import 'element_body.dart';

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
          element: DashboardElement.SceneItems,
          widget: const Text('PLACEHOLDER'),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.SceneItemsAudio,
          widget: const Text('PLACEHOLDER'),
          canBeNotVisible: false,
          visible: true,
        ),
        PreviewConfig(
          element: DashboardElement.SceneItems,
          widget: const Text('PLACEHOLDER'),
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
          padding: const EdgeInsets.only(top: 18.0),
          buildDefaultDragHandles: false,
          itemCount: elements.length,
          proxyDecorator: (child, index, animation) => AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue =
                  Curves.easeInOut.transform(animation.value);
              final double elevation = lerpDouble(0, 6, animValue)!;
              return Material(
                elevation: elevation,
                type: MaterialType.transparency,
                child: child,
              );
            },
            child: child,
          ),
          itemBuilder: (context, index) => ElementBody(
            key: ValueKey(elements[index]),
            index: index,
            config: config.firstWhere(
              (config) => config.element == elements[index],
              orElse: () => PreviewConfig(
                element: elements[index],
                widget: const Text('Missing!'),
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
