import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stream_chat/stream_chat.dart';

import '../../../../shared/general/base/base_card.dart';
import 'stats/stats.dart';

class StreamWidgets extends StatelessWidget {
  const StreamWidgets({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        Flexible(
          child: BaseCard(
            title: 'Chat',
            rightPadding: 12.0,
            paddingChild: EdgeInsets.all(0),
            child: SizedBox(
              height: 550.0,
              child: StreamChat(
                usernameRowPadding: true,
              ),
            ),
          ),
        ),
        Flexible(
          child: BaseCard(
            title: 'Stats',
            leftPadding: 12.0,
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
