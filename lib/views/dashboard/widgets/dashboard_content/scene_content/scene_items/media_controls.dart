import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/icon_button.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/media/media_status.dart';

export '../../../../../../types/classes/media/media_status.dart'
    show isMediaInputKind;

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
              kMediaStatePlaying;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _button(
                icon: CupertinoIcons.arrow_counterclockwise,
                semanticLabel: 'Restart ${this.widget.inputName}',
                onTap: () => dashboardStore.triggerMediaAction(
                  this.widget.inputName,
                  kMediaActionRestart,
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
                  playing ? kMediaActionPause : kMediaActionPlay,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
