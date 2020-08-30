import 'package:flutter/material.dart';

import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContentMobile extends StatelessWidget {
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
                child: SceneItems(),
              ),
              AudioInputs(),
            ]),
          )
        ],
      ),
    );
  }
}
