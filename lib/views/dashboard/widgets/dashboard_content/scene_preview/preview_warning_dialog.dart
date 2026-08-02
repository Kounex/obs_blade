import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';

class PreviewWarningDialog extends StatelessWidget {
  final void Function(bool) onOk;

  const PreviewWarningDialog({
    super.key,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    /// [bodyWidget] instead of [body] so the long copy is left-aligned (the
    /// plain body is centered by the dialog) plus a semantic warning
    /// affordance
    return ConfirmationDialog(
      title: 'Warning on scene preview',
      bodyWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Theme.of(context).extension<AppStatusColors>()!.warning,
              size: 40.0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'OBS WebSocket is not able to retrieve a video stream of the current scene. This implementation is a workaround. It does not reflect your actual OBS performance.\n\nBeware that this might cause higher battery usage and/or OBS itself (your PC) might suffer performance issues.\n\nUse with caution!',
            textAlign: TextAlign.left,
          ),
        ],
      ),
      onOk: (checked) => this.onOk(checked),
      enableDontShowAgainOption: true,
      okText: 'Ok',
      noText: 'Cancel',
    );
  }
}
