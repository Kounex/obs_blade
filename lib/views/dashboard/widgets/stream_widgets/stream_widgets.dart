import 'package:flutter/material.dart';

import '../../../../shared/general/base_card.dart';
import 'stats/stats.dart';
import 'twitch_chat/twitch_chat.dart';

class StreamWidgets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BaseCard(
            title: 'Chat',
            noPaddingChild: true,
            child: SizedBox(
              height: 500.0,
              child: TwitchChat(
                usernameRowPadding: true,
              ),
            ),
          ),
        ),
        Expanded(
          child: BaseCard(
            title: 'Stats',
            noPaddingChild: true,
            child: SizedBox(
              height: 500.0,
              child: Stats(),
            ),
          ),
        ),
      ],
    );
  }
}
