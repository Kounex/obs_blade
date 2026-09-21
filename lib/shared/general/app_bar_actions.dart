import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/shared/general/base/icon_button.dart';
import 'package:obs_blade/utils/modal_handler.dart';

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
  }) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;

    switch (Theme.of(context).platform) {
      case TargetPlatform.iOS || TargetPlatform.macOS:
        showCupertinoModalPopup(
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
                            ? TextStyle(color: textColors.textTertiary)
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
        );
      case _:
        ModalHandler.showBaseBottomSheet(
          context: context,
          barrierDismissible: true,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (actionSheetTitle != null) ...[
                Text(actionSheetTitle),
                const BaseDivider(),
              ],
              ...actions.map(
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
                      ? statusColors.destructiveText
                      : null,
                  iconColor: action.isDestructive
                      ? statusColors.destructiveText
                      : null,
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      springy: false,
      onTap: () => AppBarActions.showActions(
        context,
        actionSheetTitle: this.actionSheetTitle,
        actions: this.actions,
      ),
      child: const SizedBox(
        width: kBaseIconButtonMinHitArea,
        height: kBaseIconButtonMinHitArea,
        child: Center(child: Icon(CupertinoIcons.ellipsis)),
      ),
    );
  }
}
