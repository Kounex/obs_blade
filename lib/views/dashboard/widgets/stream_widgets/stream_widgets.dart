import 'package:flutter/material.dart';

import '../../../../utils/styling_helper.dart';
import 'stats/stats.dart';
import 'twitch_chat/twitch_chat.dart';

class StreamWidgets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(left: 24.0, right: 12.0),
            child: Column(
              children: [
                Container(
                  color: StylingHelper.MAIN_BLUE,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Sources',
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Divider(height: 0.0),
                SizedBox(
                  height: 250.0,
                  child: TwitchChat(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(left: 12.0, right: 24.0),
            child: Column(
              children: [
                Container(
                  color: StylingHelper.MAIN_BLUE,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      'Audio',
                      style: Theme.of(context)
                          .textTheme
                          .subtitle1
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Divider(height: 0.0),
                SizedBox(
                  height: 250.0,
                  child: Stats(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
