import 'package:flutter/material.dart';

import '../../../../models/enums/dashboard_element.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/responsive_widget_wrapper.dart';
import '../obs_widgets/stats/stats.dart';
import 'dashboard_element_card.dart';
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

/// Builds the regular (non-streaming) dashboard body from
/// [DashboardElementsOrder], composing adjacent Scene Items/Audio into the
/// existing mobile-card / tablet-row layouts.
///
/// Vertical rhythm lives here and nowhere else: [AppSpacing.md] between
/// element blocks; the cards/bare rows carry no vertical outer margin.
List<Widget> buildOrderedDashboardSlivers(List<DashboardElement> order) {
  final List<Widget> columnChildren = [];
  final Set<DashboardElement> consumed = {};

  void addBlock(List<Widget> block) {
    if (block.isEmpty) {
      return;
    }
    if (columnChildren.isNotEmpty) {
      columnChildren.add(const SizedBox(height: AppSpacing.md));
    }
    columnChildren.addAll(block);
  }

  for (int i = 0; i < order.length; i++) {
    final DashboardElement current = order[i];
    if (consumed.contains(current)) {
      continue;
    }

    final DashboardElement? next = i + 1 < order.length ? order[i + 1] : null;

    if (next != null &&
        _kScenePair.contains(current) &&
        _kScenePair.contains(next) &&
        current != next) {
      consumed.add(next);
      final bool audioFirst = current == DashboardElement.SceneItemsAudio;
      addBlock([
        ResponsiveWidgetWrapper(
          mobileWidget: DashboardElementCard(
            child: SceneContentMobile(audioFirst: audioFirst),
          ),
          tabletWidget: SceneContent(audioFirst: audioFirst),
        ),
      ]);
      continue;
    }

    addBlock(_buildStandalone(current));
  }

  return [Column(children: columnChildren)];
}

List<Widget> _buildStandalone(DashboardElement element) {
  switch (element) {
    case DashboardElement.ExposedProfile:
      return const [ProfileSceneCollection()];
    case DashboardElement.ExposedControls:
      return const [ExposedControls()];
    case DashboardElement.SceneButtons:
      return const [
        StaleStateBadge(),
        Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: AppSpacing.xxl,
              left: AppSpacing.md,
              right: AppSpacing.md,
            ),
            child: SceneButtons(),
          ),
        ),
      ];
    case DashboardElement.StudioModeTransition:
      return const [StaleGuard(child: StudioModeTransitionButton())];
    case DashboardElement.StudioModeConfig:
      return const [
        StaleGuard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              StudioModeCheckbox(),
              SizedBox(width: AppSpacing.md),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.md),
        StaleGuard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TransitionControls(),
              SizedBox(width: AppSpacing.md),
            ],
          ),
        ),
      ];
    case DashboardElement.ScenePreview:
      return const [DashboardElementCard(child: ScenePreview())];
    case DashboardElement.SceneItems:
      return const [
        DashboardElementCard(
          title: 'Scene Items',
          child: SizedBox(height: 400.0, child: SceneItems()),
        ),
      ];
    case DashboardElement.SceneItemsAudio:
      return const [
        DashboardElementCard(
          title: 'Audio',
          child: SizedBox(height: 400.0, child: AudioInputs()),
        ),
      ];
    case DashboardElement.StreamChat:
      // Retired — chat is a dedicated tab now; the element is filtered from
      // the order at read time. Case kept so the switch stays exhaustive.
      return const [];
    case DashboardElement.OBSStats:
      return const [
        /// Phone: no wrapping card - the inner stat containers are cards
        /// already, so an outer one doubled the chrome. The dots get bottom
        /// spacing so they don't sit on the first card. Tablet keeps the
        /// titled full-width card.
        ResponsiveWidgetWrapper(
          mobileWidget: SizedBox(
            height: 650.0,
            child: Stats(
              pageIndicatorPadding: EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
            ),
          ),
          tabletWidget: DashboardElementCard(
            title: 'Stats',
            child: SizedBox(height: 650.0, child: Stats()),
          ),
        ),
      ];
  }
}
