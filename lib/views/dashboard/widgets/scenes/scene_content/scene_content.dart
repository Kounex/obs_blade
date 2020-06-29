import 'package:flutter/material.dart';

import 'audio_inputs.dart';
import 'scene_items.dart';

class SceneContent extends StatelessWidget {
  final bool tabbed;

  SceneContent({this.tabbed = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Text('Scene Items'),
              ),
              Tab(
                child: Text('Audio'),
              )
            ],
          ),
          SizedBox(
            height: 250,
            child:
                TabBarView(physics: NeverScrollableScrollPhysics(), children: [
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: Scrollbar(
                  child: ListView(
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.all(0.0),
                    children: [
                      SceneItems(),
                    ],
                  ),
                ),
              ),
              ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: 24.0),
                children: [
                  AudioInputs(),
                ],
              ),
            ]),
          )
        ],
      ),
    );
    // TODO: 2 modes: above in tabbar if screen width not big (phone) and both
    // visible if width big enough (tablet) could also be toggleable
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                color: Theme.of(context).cardColor,
                height: 30.0,
                alignment: Alignment.center,
                child: Text('Sources'),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).cardColor,
                height: 30.0,
                alignment: Alignment.center,
                child: Text('Audio'),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SceneItems(),
              ),
            ),
            VerticalDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: AudioInputs(),
              ),
            )
          ],
        ),
      ],
    );
  }
}
