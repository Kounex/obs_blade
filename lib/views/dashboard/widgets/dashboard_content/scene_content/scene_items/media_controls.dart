import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/icon_button.dart';
import '../../../../../../stores/views/dashboard.dart';

/// Media input kinds that answer the OBS media-input requests
bool isMediaInputKind(String? inputKind) =>
    inputKind != null &&
    (inputKind.startsWith('ffmpeg_source') ||
        inputKind.startsWith('vlc_source'));

/// Compact transport for a media source row: restart + play/pause. The
/// state comes from GetMediaInputStatus (requested on first build) and the
/// MediaInput* events - a playing clip shows pause, anything else play.
class MediaControls extends StatefulWidget {
  final String inputName;

  const MediaControls({super.key, required this.inputName});

  @override
  State<MediaControls> createState() => _MediaControlsState();
}

class _MediaControlsState extends State<MediaControls> {
  @override
  void initState() {
    super.initState();
    GetIt.instance<DashboardStore>().requestMediaStatus(this.widget.inputName);
  }

  Widget _button({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onTap,
  }) => Semantics(
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    child: Pressable(
      haptic: true,
      onTap: onTap,
      child: SizedBox(
        width: kBaseIconButtonMinHitArea,
        height: kBaseIconButtonMinHitArea,
        child: Center(child: Icon(icon, size: 20.0)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    return StaleGuard(
      child: Observer(
        builder: (context) {
          final bool playing =
              dashboardStore.mediaStates[this.widget.inputName] ==
              'OBS_MEDIA_STATE_PLAYING';

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                icon: CupertinoIcons.arrow_counterclockwise,
                semanticLabel: 'Restart ${this.widget.inputName}',
                onTap: () => dashboardStore.triggerMediaAction(
                  this.widget.inputName,
                  'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_RESTART',
                ),
              ),
              _button(
                icon: playing
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                semanticLabel: playing
                    ? 'Pause ${this.widget.inputName}'
                    : 'Play ${this.widget.inputName}',
                onTap: () => dashboardStore.triggerMediaAction(
                  this.widget.inputName,
                  playing
                      ? 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PAUSE'
                      : 'OBS_WEBSOCKET_MEDIA_INPUT_ACTION_PLAY',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
