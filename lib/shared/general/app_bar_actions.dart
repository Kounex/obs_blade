import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class AppBarActionEntry {
  final String title;

  /// Only used on non apple OS where we have a bottom sheet
  final Widget? leading;

  /// Only used on non apple OS where we have a bottom sheet
  final IconData? leadingIcon;

  /// Only used on non apple OS where we have a bottom sheet
  final Widget? trailing;
  final void Function()? onAction;

  final bool isDestructive;

  AppBarActionEntry({
    required this.title,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.onAction,
    this.isDestructive = false,
  });
}

class AppBarActions extends StatelessWidget {
  final String? actionSheetTitle;
  final List<AppBarActionEntry> actions;

  const AppBarActions({
    super.key,
    this.actionSheetTitle,
    required this.actions,
  });

  /// The adaptive action-sheet opener, reusable outside an app bar context:
  /// Cupertino action sheet on Apple platforms, modal bottom sheet elsewhere
  static void showActions(
    BuildContext context, {
    String? actionSheetTitle,
    required List<AppBarActionEntry> actions,
  }) => switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: actionSheetTitle != null ? Text(actionSheetTitle) : null,
          actions: actions
              .map(
                (action) => CupertinoActionSheetAction(
                  isDestructiveAction: action.isDestructive,
                  onPressed: () {
                    if (action.onAction != null) {
                      Navigator.of(context).pop();
                      action.onAction!.call();
                    }
                  },
                  child: Text(
                    action.title,
                    style: action.onAction == null
                        ? const TextStyle(color: CupertinoColors.inactiveGray)
                        : null,
                  ),
                ),
              )
              .toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    ),
    _ => ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actionSheetTitle != null) ...[
            Text(actionSheetTitle),
            const BaseDivider(),
          ],
          ...ListTile.divideTiles(
            context: context,
            color: StylingHelper.light_divider_color.withOpacity(0.0),
            tiles: actions.map(
              (action) => ListTile(
                onTap: () {
                  if (action.onAction != null) {
                    Navigator.of(context).pop();
                    action.onAction!.call();
                  }
                },
                enabled: action.onAction != null,
                title: Text(action.title),
                leading:
                    action.leading ??
                    (action.leadingIcon != null
                        ? Icon(action.leadingIcon, size: 24.0)
                        : null),
                trailing: action.trailing,
                visualDensity: VisualDensity.comfortable,
                textColor: action.isDestructive
                    ? CupertinoColors.destructiveRed
                    : null,
                iconColor: action.isDestructive
                    ? CupertinoColors.destructiveRed
                    : null,
              ),
            ),
          ),
        ],
      ),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(CupertinoIcons.ellipsis),
      onPressed: () => AppBarActions.showActions(
        context,
        actionSheetTitle: this.actionSheetTitle,
        actions: this.actions,
      ),
    );
  }
}
