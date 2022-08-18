import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../general/base/checkbox.dart';

class InfoDialog extends StatefulWidget {
  final String? title;
  final String body;

  final bool enableDontShowAgainOption;

  final Function(bool checked)? onPressed;

  const InfoDialog({
    Key? key,
    required this.body,
    this.title,
    this.enableDontShowAgainOption = false,
    this.onPressed,
  }) : super(key: key);

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  bool _dontShowChecked = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: this.widget.title != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(this.widget.title!),
            )
          : null,
      content: Column(
        children: [
          Text(
            this.widget.body,
            textAlign: TextAlign.center,
          ),
          if (this.widget.enableDontShowAgainOption)
            Padding(
              padding: const EdgeInsets.only(top: 14.0),
              child: Transform.translate(
                offset: const Offset(-4, 0),
                child: Row(
                  children: [
                    Material(
                      type: MaterialType.transparency,
                      child: BaseCheckbox(
                        value: _dontShowChecked,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (checked) =>
                            setState(() => _dontShowChecked = checked!),
                      ),
                    ),
                    const Text('Don\'t show this again'),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          isDefaultAction: false,
          onPressed: () {
            this.widget.onPressed?.call(_dontShowChecked);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
