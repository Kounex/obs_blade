import 'package:flutter/material.dart';

import '../../shared/design/design.dart';
import '../../shared/general/base/constrained_box.dart';
import '../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../utils/routing_helper.dart';
import '../dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

/// Chat tab root: the standalone home for stream chat - usable with or
/// without an OBS session (chat state lives in the global settings box and
/// the GetIt chat stores; the stores connect on login restore / channel
/// select regardless of any surface). The dashboard chat pane is untouched
/// and remains the live co-display surface.
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        title: 'Chat',
        customBody: Padding(
          padding: EdgeInsets.only(
            /// Breathing room between the nav bar and the chat chrome
            top: AppSpacing.md,

            /// Full available height, resting the standard gap above the
            /// glass tab bar
            bottom: tabBarBottomPadding(context),
          ),
          child: Center(
            child: BaseConstrainedBox(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: StreamChat(
                usernameRowPadding: true,
                proRoute: ChatTabRoutingKeys.Pro.route,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
