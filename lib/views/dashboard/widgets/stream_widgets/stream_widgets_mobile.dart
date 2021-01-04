import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stream_chat/stream_chat.dart';

import 'stats/stats.dart';

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
              Material(
                color:
                    Theme.of(context).cupertinoOverrideTheme.barBackgroundColor,
                child: TabBar(
                  tabs: [
                    Tab(
                      child: Text('Chat'),
                    ),
                    Tab(
                      child: Text('Stats'),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 575.0,
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 12.0, left: 8.0, right: 8.0),
                      child: StreamChat(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Stats(
                        pageIndicatorPadding: EdgeInsets.only(
                          top: 12.0,
                          bottom: 12.0,
                        ),
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
