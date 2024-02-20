import 'package:flutter/cupertino.dart';
import 'package:obs_blade/shared/general/custom_sliver_list.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/resizeable_scene_preview.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_preview/scene_preview.dart';

class DashboardContentStreaming extends StatelessWidget {
  const DashboardContentStreaming({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomSliverList(
      children: [
        ResizeableScenePreview(),
        SizedBox(
          height: 400.0,
          child: StreamChat(
            usernameRowExpandable: true,
            usernameRowBeneath: true,
            usernameRowPadding: true,
          ),
        ),
      ],
    );
  }
}
