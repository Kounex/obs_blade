import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/adaptive_dialog/adaptive_dialog_action.dart';
import 'package:obs_blade/utils/styling_helper.dart';

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
  final Widget? titleWidget;

  final String? body;
  final Widget? bodyWidget;

  final bool enableDontShowAgainOption;

  final List<DialogActionConfig>? actions;

  const BaseAdaptiveDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.body,
    this.bodyWidget,
    this.enableDontShowAgainOption = false,
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
      title: this.widget.titleWidget ??
          (this.widget.title != null
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom: StylingHelper.isApple(context) ? 8.0 : 0.0,
                  ),
                  child: Text(this.widget.title!),
                )
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0) +
          EdgeInsets.only(
            top: this.widget.title == null && this.widget.titleWidget == null
                ? 24.0
                : 16.0,
            bottom: 12.0,
          ),
      backgroundColor: Theme.of(context).cardColor,
      elevation: 0,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          this.widget.bodyWidget ?? Text(this.widget.body!),
          if (this.widget.enableDontShowAgainOption)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  type: MaterialType.transparency,
                  child: BaseCheckbox(
                    value: _isDontShowChecked,
                    text: 'Don\'t show this again',
                    smallText: true,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (checked) =>
                        setState(() => _isDontShowChecked = checked!),
                  ),
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
                if (config.popOnAction) {
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
