import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/dashboard.dart';
import 'audio_slider.dart';

class AudioInputs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(
      builder: (_) => ListView(
        padding: EdgeInsets.only(top: 24.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Align(
              child: Text(
                'Global',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Column(
              children: dashboardStore.globalAudioSceneItems
                  .map((globalAudioItem) =>
                      AudioSlider(audioSceneItem: globalAudioItem))
                  .toList(),
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
            child: Align(
              child: Text(
                'Scene',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Column(
              children: dashboardStore.currentAudioSceneItems
                  .map((currentAudioSceneItem) =>
                      AudioSlider(audioSceneItem: currentAudioSceneItem))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
