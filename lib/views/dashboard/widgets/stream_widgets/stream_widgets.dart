import 'package:flutter/material.dart';

import '../../../../shared/general/base/card.dart';
import 'stats/stats.dart';
import 'stream_chat/stream_chat.dart';

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
              height: 650.0,
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
              height: 650.0,
              child: Stats(),
            ),
          ),
        ),
      ],
    );
  }
}
