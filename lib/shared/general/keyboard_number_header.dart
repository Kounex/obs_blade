import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class KeyboardNumberHeader extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;

  final void Function()? onDone;

  const KeyboardNumberHeader({
    super.key,
    required this.child,
    required this.focusNode,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
        keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
        keyboardBarColor:
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).cardColor,
        nextFocus: false,
        actions: [
          KeyboardActionsItem(
            focusNode: this.focusNode,
            onTapAction: this.onDone,
          ),
        ],
      ),
      disableScroll: true,
      child: this.child,
    );
  }
}
