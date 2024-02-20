import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog.dart';

class InfoDialog extends StatelessWidget {
  final String? title;
  final String body;

  final bool enableDontShowAgainOption;

  final Function(bool isDontShowAgainChecked)? onPressed;

  const InfoDialog({
    Key? key,
    required this.body,
    this.title,
    this.enableDontShowAgainOption = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BaseAdaptiveDialog(
      title: this.title,
      body: this.body,
      enableDontShowAgainOption: this.enableDontShowAgainOption,
      actions: [
        DialogActionConfig(
          isDefaultAction: false,
          onPressed: (isDontShowAgainChecked) =>
              this.onPressed?.call(isDontShowAgainChecked),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
