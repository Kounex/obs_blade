import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/shared/network.dart';
import '../../../types/enums/request_type.dart';
import '../../../utils/modal_handler.dart';
import '../../../utils/network_helper.dart';
import '../widgets/scenes/start_stop_recording_dialog.dart';
import '../widgets/scenes/start_stop_streaming_dialog.dart';

class RecordStreamService {
  static void triggerRecordStartStop(
    BuildContext context,
    bool isRecording,
    bool checkedDontShowRecordStart,
    bool checkedDontShowRecordStop,
  ) {
    VoidCallback onRecordStartStop = () => NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.StartStopRecording,
        );

    (isRecording && !checkedDontShowRecordStop) ||
            (!isRecording && !checkedDontShowRecordStart)
        ? ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: StartStopRecordingDialog(
              isRecording: isRecording,
              onRecordStartStop: onRecordStartStop,
            ),
          )
        : onRecordStartStop();
  }

  static void triggerStreamStartStop(
    BuildContext context,
    bool isLive,
    bool checkedDontShowStreamStart,
    bool checkedDontShowStreamStop,
  ) {
    VoidCallback onStreamStartStop = () => NetworkHelper.makeRequest(
          GetIt.instance<NetworkStore>().activeSession!.socket,
          RequestType.StartStopStreaming,
        );

    (isLive && !checkedDontShowStreamStop) ||
            (!isLive && !checkedDontShowStreamStart)
        ? ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: StartStopStreamingDialog(
              isLive: isLive,
              onStreamStartStop: onStreamStartStop,
            ),
          )
        : onStreamStartStop();
  }
}
