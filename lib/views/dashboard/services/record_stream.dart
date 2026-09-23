import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/views/dashboard.dart';
import '../../../types/enums/request_type.dart';
import '../../../utils/modal_handler.dart';
import '../widgets/dashboard_content/dialogs/start_stop_recording_dialog.dart';
import '../widgets/dashboard_content/dialogs/start_stop_streaming_dialog.dart';

class RecordStreamService {
  static void triggerRecordStartStop(
    BuildContext context,
    bool isRecording,
    bool checkedDontShowRecordStart,
    bool checkedDontShowRecordStop,
  ) {
    HapticFeedback.mediumImpact();
    (isRecording && !checkedDontShowRecordStop) ||
            (!isRecording && !checkedDontShowRecordStart)
        ? ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: StartStopRecordingDialog(
              isRecording: isRecording,
              onRecordStartStop: () =>
                  GetIt.instance<DashboardStore>().sendMutation(
                    RequestType.ToggleRecord,
                    label: 'Recording start/stop',
                  ),
            ),
          )
        : GetIt.instance<DashboardStore>().sendMutation(
            RequestType.ToggleRecord,
            label: 'Recording start/stop',
          );
  }

  static void triggerStreamStartStop(
    BuildContext context,
    bool isLive,
    bool checkedDontShowStreamStart,
    bool checkedDontShowStreamStop,
  ) {
    HapticFeedback.mediumImpact();
    (isLive && !checkedDontShowStreamStop) ||
            (!isLive && !checkedDontShowStreamStart)
        ? ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: StartStopStreamingDialog(
              isLive: isLive,
              onStreamStartStop: () =>
                  GetIt.instance<DashboardStore>().sendMutation(
                    RequestType.ToggleStream,
                    label: 'Stream start/stop',
                  ),
            ),
          )
        : GetIt.instance<DashboardStore>().sendMutation(
            RequestType.ToggleStream,
            label: 'Stream start/stop',
          );
  }
}
