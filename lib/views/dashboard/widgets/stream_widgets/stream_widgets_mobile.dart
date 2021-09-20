import 'package:flutter/material.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/stream_chat/stream_chat.dart';

import 'stats/stats.dart';

class StreamWidgetsMobile extends StatelessWidget {
  const StreamWidgetsMobile({Key? key}) : super(key: key);

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
                color: Theme.of(context)
                    .cupertinoOverrideTheme!
                    .barBackgroundColor,
                child: const TabBar(
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
              const SizedBox(
                height: 575.0,
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0),
                      child: StreamChat(),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 12.0),
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
