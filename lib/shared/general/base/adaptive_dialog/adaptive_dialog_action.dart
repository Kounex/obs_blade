import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveDialogAction extends StatelessWidget {
  final Widget child;

  final bool isDestructiveAction;
  final bool isDefaultAction;

  final void Function()? onPressed;

  const AdaptiveDialogAction({
    super.key,
    required this.child,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => CupertinoDialogAction(
          onPressed: this.onPressed,
          isDefaultAction: this.isDefaultAction,
          isDestructiveAction: this.isDestructiveAction,
          child: this.child,
        ),
      _ => TextButton(
          onPressed: this.onPressed,
          style: this.isDestructiveAction
              ? ButtonStyle(
                  foregroundColor: const MaterialStatePropertyAll(
                      CupertinoColors.destructiveRed),
                  overlayColor: MaterialStatePropertyAll(
                    CupertinoColors.destructiveRed.withOpacity(0.1),
                  ),
                )
              : null,
          child: this.child,
        ),
    };
  }
}
