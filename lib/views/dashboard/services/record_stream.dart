import 'package:flutter/material.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/start_stop_recording_dialog.dart';
import 'package:obs_blade/views/dashboard/widgets/scenes/start_stop_streaming_dialog.dart';
import 'package:provider/provider.dart';

class RecordStreamService {
  static void triggerRecordStartStop(
    BuildContext context,
    bool isRecording,
    bool checkedDontShowRecordStart,
    bool checkedDontShowRecordStop,
  ) {
    VoidCallback onRecordStartStop = () => NetworkHelper.makeRequest(
          context.read<NetworkStore>().activeSession!.socket,
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
          context.read<NetworkStore>().activeSession!.socket,
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
