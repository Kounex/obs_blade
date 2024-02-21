import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/resizeable_scene_preview.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_buttons/scene_buttons.dart';

class DashboardContentStreaming extends StatelessWidget {
  const DashboardContentStreaming({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ResizeableScenePreview(
            resizeable: false,
          ),
          const SizedBox(height: 12.0),
          const SceneButtons(
            size: 64,
          ),
          const SizedBox(height: 12.0),
          const Flexible(
            child: StreamChat(
              usernameRowExpandable: true,
              usernameRowBeneath: true,
              usernameRowPadding: true,
            ),
          ),
          SizedBox(
            height: 50 + MediaQuery.viewInsetsOf(context).bottom,
          ),
        ],
      ),
    );
  }
}
