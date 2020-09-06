import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBarCupertinoActionEntry {
  final String title;
  final void Function() onAction;

  final bool isDestructive;

  AppBarCupertinoActionEntry(
      {this.title, this.onAction, this.isDestructive = false});
}

class AppBarCupertinoActions extends StatelessWidget {
  final String actionSheetTitle;
  final List<AppBarCupertinoActionEntry> actions;

  AppBarCupertinoActions({this.actionSheetTitle, @required this.actions});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        CupertinoIcons.ellipsis,
        size: 32.0,
      ),
      onPressed: () => showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return CupertinoActionSheet(
            title: this.actionSheetTitle != null ? Text('Actions') : null,
            actions: this
                .actions
                .map(
                  (action) => CupertinoActionSheetAction(
                    child: Text(action.title),
                    isDestructiveAction: action.isDestructive,
                    onPressed: () {
                      Navigator.of(context).pop();
                      action.onAction?.call();
                    },
                  ),
                )
                .toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          );
        },
      ),
    );
  }
}
