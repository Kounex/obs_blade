import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/general/nested_list_manager.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../placeholder_scene_item.dart';
import 'audio_slider.dart';

class AudioInputs extends StatefulWidget {
  const AudioInputs({Key? key}) : super(key: key);

  @override
  _AudioInputsState createState() => _AudioInputsState();
}

class _AudioInputsState extends State<AudioInputs>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _controller = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return Observer(
      builder: (_) => NestedScrollManager(
        parentScrollController:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: ListView(
            controller: _controller,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(top: 24.0),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
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
                children: dashboardStore.globalInputs.isNotEmpty
                    ? dashboardStore.globalInputs
                        .map(
                          (globalInput) => AudioSlider(input: globalInput),
                          // (globalInput) => VisibilitySlideWrapper(
                          //   sceneItem: globalAudioItem,
                          //   sceneItemType: SceneItemType.Audio,
                          //   child: AudioSlider(audioSceneItem: globalAudioItem),
                          // ),
                        )
                        .toList()
                    : [
                        const PlaceholderSceneItem(
                            text: 'No Global Audio source available...'),
                        const SizedBox(height: 12.0),
                      ],
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
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
                children: dashboardStore.currentInputs.isNotEmpty
                    ? dashboardStore.currentInputs
                        .map(
                          (input) => AudioSlider(input: input),

                          // (currentAudioSceneItem) => VisibilitySlideWrapper(
                          //   sceneItem: currentAudioSceneItem,
                          //   sceneItemType: SceneItemType.Audio,
                          //   child: AudioSlider(
                          //       audioSceneItem: currentAudioSceneItem),
                          // ),
                        )
                        .toList()
                    : [
                        const PlaceholderSceneItem(
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
