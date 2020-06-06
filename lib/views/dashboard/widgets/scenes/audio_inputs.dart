import 'package:flutter/material.dart';
import 'package:obs_station/stores/views/dashboard.dart';
import 'package:obs_station/views/dashboard/widgets/scenes/audio_slider.dart';
import 'package:provider/provider.dart';

class AudioInputs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Column(
      children: [
        Text('Global'),
        ...dashboardStore.globalAudioItems
            .map((globalAudioItem) =>
                AudioSlider(audioSceneItem: globalAudioItem))
            .toList(),
        Divider(),
        Text('Scene'),
        ...dashboardStore.currentAudioSceneItems
            .map((currentAudioSceneItem) =>
                AudioSlider(audioSceneItem: currentAudioSceneItem))
            .toList(),
      ],
    );
  }
}
