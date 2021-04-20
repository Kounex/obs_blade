import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/start_stop_recording_dialog.dart';
import 'package:provider/provider.dart';

import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../utils/network_helper.dart';

class RecordingControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.read<DashboardStore>();

    return Observer(
      builder: (context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 128.0,
            child: ElevatedButton.icon(
              onPressed: () => ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: StartStopRecordingDialog(
                  isRecording: dashboardStore.isRecording,
                ),
              ),
              icon: Icon(
                dashboardStore.isRecording
                    ? CupertinoIcons.stop
                    : CupertinoIcons.recordingtape,
              ),
              style: ElevatedButton.styleFrom(
                primary: dashboardStore.isRecording
                    ? CupertinoColors.destructiveRed
                    : Colors.green,
              ),
              label: Text(dashboardStore.isRecording ? 'Stop' : 'Start'),
            ),
          ),
          SizedBox(width: 12.0),
          SizedBox(
            width: 128.0,
            child: ElevatedButton.icon(
              onPressed: dashboardStore.isRecording
                  ? () => NetworkHelper.makeRequest(
                        context.read<NetworkStore>().activeSession!.socket,
                        context.read<DashboardStore>().isRecordingPaused
                            ? RequestType.ResumeRecording
                            : RequestType.PauseRecording,
                      )
                  : null,
              icon: Icon(
                dashboardStore.isRecordingPaused
                    ? CupertinoIcons.play
                    : CupertinoIcons.pause,
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.orange,
              ),
              label:
                  Text(dashboardStore.isRecordingPaused ? 'Resume' : 'Pause'),
            ),
          ),
        ],
      ),
    );
  }
}
