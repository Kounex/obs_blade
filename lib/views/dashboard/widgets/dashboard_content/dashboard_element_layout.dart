import 'package:flutter/material.dart';

import '../../../../models/enums/dashboard_element.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../shared/general/base/divider.dart';
import '../../../../shared/general/responsive_widget_wrapper.dart';
import '../obs_widgets/obs_widgets.dart';
import '../obs_widgets/obs_widgets_mobile.dart';
import '../obs_widgets/stats/stats.dart';
import '../obs_widgets/stream_chat/stream_chat.dart';
import 'exposed_controls/exposed_controls.dart';
import 'profile_scene_collection/profile_scene_collection.dart';
import 'scene_buttons/scene_buttons.dart';
import 'scene_content/audio_inputs/audio_inputs.dart';
import 'scene_content/scene_content.dart';
import 'scene_content/scene_content_mobile.dart';
import 'scene_content/scene_items/scene_items.dart';
import 'scene_preview/scene_preview.dart';
import 'studio_mode_checkbox.dart';
import 'studio_mode_transition_button.dart';
import 'transition_controls.dart';

const Set<DashboardElement> _kScenePair = {
  DashboardElement.SceneItems,
  DashboardElement.SceneItemsAudio,
};

const Set<DashboardElement> _kWidgetsPair = {
  DashboardElement.StreamChat,
  DashboardElement.OBSStats,
};

/// Builds the regular (non-streaming) dashboard body from
/// [DashboardElementsOrder], composing adjacent Scene Items/Audio and
/// Chat/Stats into the existing mobile-tab / tablet-row layouts.
List<Widget> buildOrderedDashboardSlivers(List<DashboardElement> order) {
  final List<Widget> columnChildren = [];
  final Set<DashboardElement> consumed = {};

  for (int i = 0; i < order.length; i++) {
    final DashboardElement current = order[i];
    if (consumed.contains(current)) {
      continue;
    }

    final DashboardElement? next =
        i + 1 < order.length ? order[i + 1] : null;

    if (next != null &&
        _kScenePair.contains(current) &&
        _kScenePair.contains(next) &&
        current != next) {
      consumed.add(next);
      final bool audioFirst = current == DashboardElement.SceneItemsAudio;
      columnChildren.add(
        ResponsiveWidgetWrapper(
          mobileWidget: SceneContentMobile(audioFirst: audioFirst),
          tabletWidget: SceneContent(audioFirst: audioFirst),
        ),
      );
      columnChildren.add(const SizedBox(height: AppSpacing.xl));
      continue;
    }

    if (next != null &&
        _kWidgetsPair.contains(current) &&
        _kWidgetsPair.contains(next) &&
        current != next) {
      consumed.add(next);
      final bool statsFirst = current == DashboardElement.OBSStats;
      columnChildren.add(
        ResponsiveWidgetWrapper(
          mobileWidget: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: BaseDivider(),
              ),
              OBSWidgetsMobile(statsFirst: statsFirst),
            ],
          ),
          tabletWidget: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: BaseDivider(),
              ),
              OBSWidgets(statsFirst: statsFirst),
            ],
          ),
        ),
      );
      continue;
    }

    columnChildren.addAll(_buildStandalone(current));
  }

  // Trim trailing spacer if the last composed block added one and nothing
  // followed that needed it — harmless if left; keep structure simple.
  return [
    Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(children: columnChildren),
    ),
  ];
}

List<Widget> _buildStandalone(DashboardElement element) {
  switch (element) {
    case DashboardElement.ExposedProfile:
      return const [
        ProfileSceneCollection(),
      ];
    case DashboardElement.ExposedControls:
      return const [
        ExposedControls(),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.SceneButtons:
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.xxl,
              left: 18.0,
              right: 18.0,
            ),
            child: SceneButtons(),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.StudioModeTransition:
      return const [
        StudioModeTransitionButton(),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.StudioModeConfig:
      return const [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            StudioModeCheckbox(),
            SizedBox(width: AppSpacing.xl),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TransitionControls(),
            SizedBox(width: AppSpacing.xl),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.ScenePreview:
      return const [
        ScenePreview(),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.SceneItems:
      return const [
        BaseCard(
          title: 'Scene Items',
          paddingChild: EdgeInsets.all(0),
          child: SizedBox(
            height: 400.0,
            child: SceneItems(),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.SceneItemsAudio:
      return const [
        BaseCard(
          title: 'Audio',
          paddingChild: EdgeInsets.all(0),
          child: SizedBox(
            height: 400.0,
            child: AudioInputs(),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.StreamChat:
      return const [
        BaseCard(
          title: 'Chat',
          paddingChild: EdgeInsets.all(0),
          child: SizedBox(
            height: 720.0,
            child: StreamChat(usernameRowPadding: true),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ];
    case DashboardElement.OBSStats:
      return const [
        BaseCard(
          title: 'Stats',
          paddingChild: EdgeInsets.all(0),
          child: SizedBox(
            height: 650.0,
            child: Stats(),
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ];
  }
}
