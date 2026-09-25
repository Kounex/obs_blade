import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/views/dashboard.dart';
import '../../../types/enums/request_type.dart';
import '../../../utils/modal_handler.dart';
import '../widgets/dashboard_content/dialogs/start_stop_recording_dialog.dart';
import '../widgets/dashboard_content/dialogs/start_stop_streaming_dialog.dart';

class RecordStreamService {
  /// Explicit Start / Stop instead of a Toggle: the user confirmed a
  /// direction ("Stop Streaming"), so if OBS changed state in the meantime
  /// (someone stopped it on the PC) the request fails instead of doing the
  /// opposite of what was confirmed
  static void _sendRecord(bool isRecording) =>
      GetIt.instance<DashboardStore>().sendMutation(
        isRecording ? RequestType.StopRecord : RequestType.StartRecord,
        label: isRecording ? 'Stop recording' : 'Start recording',
      );

  static void _sendStream(bool isLive) =>
      GetIt.instance<DashboardStore>().sendMutation(
        isLive ? RequestType.StopStream : RequestType.StartStream,
        label: isLive ? 'Stop stream' : 'Start stream',
      );

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
              onRecordStartStop: () => _sendRecord(isRecording),
            ),
          )
        : _sendRecord(isRecording);
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
              onStreamStartStop: () => _sendStream(isLive),
            ),
          )
        : _sendStream(isLive);
  }
}
