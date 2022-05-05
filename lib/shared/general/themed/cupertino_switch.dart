import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../dialogs/info.dart';
import '../../../utils/modal_handler.dart';

class ThemedCupertinoSwitch extends StatelessWidget {
  final bool value;
  final bool enabled;
  final Color? activeColor;
  final Function(bool) onChanged;
  final String? disabledChangeInfo;

  const ThemedCupertinoSwitch(
      {Key? key,
      required this.value,
      this.enabled = true,
      this.activeColor,
      required this.onChanged,
      this.disabledChangeInfo})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: !this.enabled && this.disabledChangeInfo != null
          ? (_) => ModalHandler.showBaseDialog(
              context: context,
              dialogWidget: InfoDialog(body: this.disabledChangeInfo!))
          : null,
      child: CupertinoSwitch(
        value: this.value,
        activeColor:
            this.activeColor ?? Theme.of(context).toggleableActiveColor,
        onChanged: this.enabled ? this.onChanged : null,
      ),
    );
  }
}
