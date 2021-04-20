import 'package:flutter/material.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';

class PreviewWarningDialog extends StatelessWidget {
  final void Function(bool) onOk;

  PreviewWarningDialog({required this.onOk});

  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: 'Warningon scene preview',
      body:
          'OBS WebSocket is not able to retrieve a video stream of the current scene. This implementation is a workaround. It does not reflect your actual OBS performance.\n\nBeware that this might cause higher battery usage and / or OBS itself (your pc) might suffer performance issues.\n\nUse with caution!',
      onOk: (checked) => this.onOk(checked),
      enableDontShowAgainOption: true,
      okText: 'Ok',
      noText: 'Cancel',
    );
  }
}
