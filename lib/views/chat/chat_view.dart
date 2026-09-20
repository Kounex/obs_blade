import 'package:flutter/material.dart';

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
            /// The tab scaffold extends bodies behind the translucent tab
            /// bar (extendBody) - same bottom clearance CustomSliverList
            /// gives the sliver-based tab views, so the chat input rests
            /// above the bar
            bottom:
                2 * kBottomNavigationBarHeight +
                MediaQuery.paddingOf(context).bottom / 2,
          ),
          child: Center(
            child: BaseConstrainedBox(
              child: StreamChat(
                usernameRowPadding: true,
                scrollArbitration: false,
                proRoute: ChatTabRoutingKeys.Pro.route,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
