import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/dialogs/confirmation.dart';
import '../../../../stores/shared/network.dart';
import '../../../../types/enums/request_type.dart';
import '../../../../utils/network_helper.dart';

class StartStopRecordingDialog extends StatelessWidget {
  final bool isRecording;

  StartStopRecordingDialog({required this.isRecording});

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: (this.isRecording ? 'Stop' : 'Start') + ' Recording',
      body: this.isRecording
          ? 'Do you want to stop recording? Got everything on tape as intended?\n\nIf yes: nice work!'
          : 'Do you want to start recording? Recording unintentionally is not as bad as suddenly starting to stream!\n\nStill asking just to be sure!',
      isYesDestructive: true,
      onOk: (_) => NetworkHelper.makeRequest(
          context.read<NetworkStore>().activeSession!.socket,
          RequestType.StartStopRecording),
    );
  }
}
