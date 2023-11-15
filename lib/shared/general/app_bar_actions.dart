import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/utils/modal_handler.dart';

class AppBarActionEntry {
  final String title;
  final void Function()? onAction;

  final bool isDestructive;

  AppBarActionEntry(
      {required this.title, this.onAction, this.isDestructive = false});
}

class AppBarActions extends StatelessWidget {
  final String? actionSheetTitle;
  final List<AppBarActionEntry> actions;

  const AppBarActions({
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
      onPressed: () => switch (Theme.of(context).platform) {
        TargetPlatform.iOS || TargetPlatform.macOS => showCupertinoModalPopup(
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
                          action.title,
                          style: action.onAction == null
                              ? TextStyle(
                                  color: CupertinoColors.systemBlue
                                      .withOpacity(0.3),
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
        _ => ModalHandler.showBaseBottomSheet(
            context: context,
            barrierDismissible: true,
            modalWidget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (this.actionSheetTitle != null) ...[
                  Text(this.actionSheetTitle!),
                  const BaseDivider(),
                ],
                ...this
                    .actions
                    .map(
                      (action) => ListTile(
                        title: Text(action.title),
                        visualDensity: VisualDensity.comfortable,
                        textColor: action.isDestructive
                            ? CupertinoColors.destructiveRed
                            : null,
                      ),
                    )
                    .toList()
              ],
            ),
          ),
      },
    );
  }
}
