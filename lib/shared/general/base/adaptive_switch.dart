import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/modal_handler.dart';
import '../../dialogs/info.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final bool enabled;
  final Color? activeColor;
  final dynamic Function(bool) onChanged;
  final String? disabledChangeInfo;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.enabled = true,
    this.activeColor,
    required this.onChanged,
    this.disabledChangeInfo,
  });

  bool _isApple(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS ||
      Theme.of(context).platform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: !this.enabled && this.disabledChangeInfo != null
          ? (_) => ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: InfoDialog(body: this.disabledChangeInfo!),
              )
          : null,
      child: _isApple(context)
          ? CupertinoSwitch(
              value: this.value,
              activeColor: this.activeColor ??
                  Theme.of(context)
                      .switchTheme
                      .trackColor!
                      .resolve({MaterialState.selected}),
              onChanged: this.enabled ? this.onChanged : null,
            )
          : Switch(
              value: this.value,
              activeColor: this.activeColor ??
                  Theme.of(context)
                      .switchTheme
                      .trackColor!
                      .resolve({MaterialState.selected}),
              activeTrackColor: (this.activeColor ??
                      Theme.of(context)
                          .switchTheme
                          .trackColor!
                          .resolve({MaterialState.selected}))!
                  .withOpacity(0.5),
              onChanged: this.enabled ? this.onChanged : null,
            ),
    );
  }
}
