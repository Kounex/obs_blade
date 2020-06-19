import 'package:flutter/material.dart';

import 'stats/stats.dart';
import 'twitch_chat/twitch_chat.dart';

class StreamWidgets extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            'Widgets',
            style: Theme.of(context).textTheme.headline4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
          child: Divider(height: 0.0),
        ),
        DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: [
                  Tab(
                    child: Text('Chat'),
                  ),
                  Tab(
                    child: Text('Stats'),
                  )
                ],
              ),
              SizedBox(
                height: 525,
                child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 24.0, bottom: 24.0, left: 8.0, right: 8.0),
                        child: TwitchChat(),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Stats(),
                      ),
                    ]),
              )
            ],
          ),
        ),
      ],
    );
  }
}
