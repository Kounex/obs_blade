import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/scene_content/placeholder_scene_item.dart';
import 'package:provider/provider.dart';

import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../shared/general/nested_list_manager.dart';
import '../visibility_slide_wrapper.dart';
import 'audio_slider.dart';

class AudioInputs extends StatefulWidget {
  @override
  _AudioInputsState createState() => _AudioInputsState();
}

class _AudioInputsState extends State<AudioInputs>
    with AutomaticKeepAliveClientMixin {
  ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DashboardStore dashboardStore = Provider.of<DashboardStore>(context);

    return Observer(
      builder: (_) => NestedScrollManager(
        parentScrollController:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        child: Scrollbar(
          controller: _controller,
          isAlwaysShown: true,
          child: ListView(
            controller: _controller,
            physics: ClampingScrollPhysics(),
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
              Column(
                children: dashboardStore.globalAudioSceneItems != null &&
                        dashboardStore.globalAudioSceneItems.length > 0
                    ? dashboardStore.globalAudioSceneItems
                        .map(
                          (globalAudioItem) => VisibilitySlideWrapper(
                            sceneItem: globalAudioItem,
                            sceneItemType: SceneItemType.Audio,
                            child: AudioSlider(audioSceneItem: globalAudioItem),
                          ),
                        )
                        .toList()
                    : [
                        PlaceholderSceneItem(
                            text: 'No Global Audio source available...')
                      ],
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
              Column(
                children: dashboardStore.currentAudioSceneItems != null &&
                        dashboardStore.currentAudioSceneItems.length > 0
                    ? dashboardStore.currentAudioSceneItems
                        .map(
                          (currentAudioSceneItem) => VisibilitySlideWrapper(
                            sceneItem: currentAudioSceneItem,
                            sceneItemType: SceneItemType.Audio,
                            child: AudioSlider(
                                audioSceneItem: currentAudioSceneItem),
                          ),
                        )
                        .toList()
                    : [
                        PlaceholderSceneItem(
                            text: 'No Audio source in this scene...')
                      ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
