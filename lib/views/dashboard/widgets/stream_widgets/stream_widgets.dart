import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stream_chat/stream_chat.dart';

import '../../../../shared/general/base_card.dart';
import 'stats/stats.dart';

class StreamWidgets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BaseCard(
            title: 'Chat',
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 550.0,
              child: StreamChat(
                usernameRowPadding: true,
              ),
            ),
          ),
        ),
        Expanded(
          child: BaseCard(
            title: 'Stats',
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 550.0,
              child: Stats(),
            ),
          ),
        ),
      ],
    );
  }
}
