import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/responsive_widget_wrapper.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/resizeable_scene_preview.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_buttons/scene_buttons.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/stream_health_strip.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

/// Streaming-mode dashboard - the "you're live" cockpit: drag-resizable
/// scene preview, one-line stream-health strip, scene buttons, and the
/// stream chat filling the rest. Phone stacks them; tablet runs preview +
/// buttons in a left column and chat full-height on the right.
///
/// Deliberately full-bleed (ratified media exception to the dashboard's
/// content-card grid): the preview keeps maximum width, the strip/buttons
/// carry their own md padding.
class DashboardContentStreaming extends StatelessWidget {
  const DashboardContentStreaming({super.key});

  /// [SceneButtons] renders its horizontal-scroll row at size + 24
  static const double _sceneButtonsHeight = 64.0 + 24.0;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Padding(
        padding: EdgeInsets.only(bottom: tabBarBottomPadding(context)),
        child: ResponsiveWidgetWrapper(
          mobileWidget: const Column(
            children: [
              ResizeableScenePreview(),
              StreamHealthStrip(),
              SceneButtons(size: 64, mode: SceneButtonsMode.horizontalScroll),
              Flexible(child: StreamChat(usernameRowPadding: true)),
            ],
          ),
          tabletWidget: LayoutBuilder(
            builder: (context, constraints) {
              /// The preview absorbs the full left column by default; the
              /// drag handle trades preview height for breathing room below
              /// the scene buttons
              final double previewHeight = math.max(
                constraints.maxHeight -
                    ResizeableScenePreview.dragHandleHeight -
                    StreamHealthStrip.height -
                    _sceneButtonsHeight,
                75.0,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: 3,
                    child: Column(
                      children: [
                        ResizeableScenePreview(
                          initialHeight: previewHeight,
                          maxHeight: previewHeight,
                        ),
                        const StreamHealthStrip(),
                        const SceneButtons(
                          size: 64,
                          mode: SceneButtonsMode.horizontalScroll,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Flexible(
                    flex: 2,
                    child: StreamChat(usernameRowPadding: true),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
