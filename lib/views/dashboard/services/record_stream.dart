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
    (isRecording && !checkedDontShowRecordStop) ||
            (!isRecording && !checkedDontShowRecordStart)
        ? ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: StartStopRecordingDialog(
              isRecording: isRecording,
              onRecordStartStop: () => NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.ToggleRecord,
              ),
            ),
          )
        : NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.ToggleRecord,
          );
  }

  static void triggerStreamStartStop(
    BuildContext context,
    bool isLive,
    bool checkedDontShowStreamStart,
    bool checkedDontShowStreamStop,
  ) {
    (isLive && !checkedDontShowStreamStop) ||
            (!isLive && !checkedDontShowStreamStart)
        ? ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: StartStopStreamingDialog(
              isLive: isLive,
              onStreamStartStop: () => NetworkHelper.makeRequest(
                GetIt.instance<NetworkStore>().activeSession!.socket,
                RequestType.ToggleStream,
              ),
            ),
          )
        : NetworkHelper.makeRequest(
            GetIt.instance<NetworkStore>().activeSession!.socket,
            RequestType.ToggleStream,
          );
  }
}
