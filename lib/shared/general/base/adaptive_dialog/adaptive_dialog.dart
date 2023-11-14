import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog_action.dart';

import '../checkbox.dart';

class DialogActionConfig {
  final Widget child;

  final bool isDestructiveAction;
  final bool isDefaultAction;

  final bool popOnAction;

  final void Function(bool isDontShowAgainChecked)? onPressed;

  DialogActionConfig({
    required this.child,
    this.isDestructiveAction = false,
    this.isDefaultAction = false,
    this.popOnAction = true,
    this.onPressed,
  });
}

class BaseAdaptiveDialog extends StatefulWidget {
  final String? title;

  final String? body;
  final Widget? bodyWidget;

  final bool enableDontShowAgainOption;

  final bool popOnAction;

  final List<DialogActionConfig>? actions;

  const BaseAdaptiveDialog({
    super.key,
    this.title,
    this.body,
    this.bodyWidget,
    this.enableDontShowAgainOption = false,
    this.popOnAction = true,
    this.actions,
  }) : assert(body != null || bodyWidget != null);

  @override
  State<BaseAdaptiveDialog> createState() => _BaseAdaptiveDialogState();
}

class _BaseAdaptiveDialogState extends State<BaseAdaptiveDialog> {
  bool _isDontShowChecked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: this.widget.title != null
          ? Padding(
              padding: EdgeInsets.only(
                bottom: Theme.of(context).platform == TargetPlatform.iOS ||
                        Theme.of(context).platform == TargetPlatform.macOS
                    ? 8.0
                    : 0.0,
              ),
              child: Text(this.widget.title!),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0) +
          const EdgeInsets.only(top: 16.0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          this.widget.bodyWidget ?? Text(this.widget.body!),
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
                        value: _isDontShowChecked,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (checked) =>
                            setState(() => _isDontShowChecked = checked!),
                      ),
                    ),
                    const Text('Don\'t show this again'),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: this
          .widget
          .actions
          ?.map(
            (config) => AdaptiveDialogAction(
              onPressed: () {
                if (this.widget.popOnAction) {
                  Navigator.of(context).pop();
                }
                config.onPressed?.call(_isDontShowChecked);
              },
              isDefaultAction: config.isDefaultAction,
              isDestructiveAction: config.isDestructiveAction,
              child: config.child,
            ),
          )
          .toList(),
    );
  }
}
