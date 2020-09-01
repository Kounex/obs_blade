import 'package:flutter/material.dart';

import 'stats/stats.dart';
import 'twitch_chat/twitch_chat.dart';

class StreamWidgetsMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                height: 525.0,
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 12.0, bottom: 24.0, left: 8.0, right: 8.0),
                      child: TwitchChat(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Stats(
                        pageIndicatorPadding: true,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
