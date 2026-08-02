import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
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

  /// Long bodies (warnings etc.) read better left-aligned - the default
  /// stays centered
  final bool leftAlignBody;

  final bool enableDontShowAgainOption;

  final List<DialogActionConfig>? actions;

  const BaseAdaptiveDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.body,
    this.bodyWidget,
    this.leftAlignBody = false,
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
    /// One-shot entrance (fade + subtle scale) on top of the route's own
    /// fade - replay-safe: [TweenAnimationBuilder] only animates when the
    /// tween changes, so the don't-show-again setState won't retrigger it
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.96 + 0.04 * value,
          child: child,
        ),
      ),
      child: AlertDialog.adaptive(
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (this.widget.leftAlignBody)
              Align(
                alignment: Alignment.centerLeft,
                child: this.widget.bodyWidget ??
                    Text(
                      this.widget.body!,
                      textAlign: TextAlign.left,
                    ),
              )
            else
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
      ),
    );
  }
}
