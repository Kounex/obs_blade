import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBarCupertinoActionEntry {
  final String? title;
  final void Function()? onAction;

  final bool isDestructive;

  AppBarCupertinoActionEntry(
      {this.title, this.onAction, this.isDestructive = false});
}

class AppBarCupertinoActions extends StatelessWidget {
  final String? actionSheetTitle;
  final List<AppBarCupertinoActionEntry> actions;

  const AppBarCupertinoActions({
    Key? key,
    this.actionSheetTitle,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(
        CupertinoIcons.ellipsis,
      ),
      onPressed: () => showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            title: this.actionSheetTitle != null
                ? Text(this.actionSheetTitle!)
                : null,
            actions: this
                .actions
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
                      action.title!,
                      style: action.onAction == null
                          ? TextStyle(
                              color:
                                  CupertinoColors.systemBlue.withOpacity(0.3),
                            )
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
    );
  }
}
