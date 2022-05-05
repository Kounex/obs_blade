import 'package:flutter/material.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../shared/general/themed/cupertino_switch.dart';
import '../color_picker/color_bubble.dart';

import '../../../../../types/extensions/string.dart';
import '../../../../../utils/modal_handler.dart';
import '../color_picker/color_picker.dart';

class ThemeRow extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? description;
  final String? colorHex;

  final bool useDivider;

  final bool? active;
  final void Function(bool)? onActiveChanged;

  final String? buttonText;
  final VoidCallback? onButtonPressed;

  final String? resetButtonText;
  final VoidCallback? onResetButtonPressed;

  final VoidCallback? onReset;
  final void Function(String)? onSave;

  const ThemeRow({
    Key? key,
    this.title,
    this.titleWidget,
    this.description,
    this.colorHex,
    this.useDivider = true,
    this.active,
    this.onActiveChanged,
    this.buttonText,
    this.onButtonPressed,
    this.resetButtonText,
    this.onResetButtonPressed,
    this.onReset,
    this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: this.onSave != null
          ? () => ModalHandler.showBaseBottomSheet(
                context: context,
                modalWidget: ColorPicker(
                  title: this.title ?? 'Title',
                  description: this.description ?? 'Description',
                  color: this.colorHex,
                  onSave: (colorHex) => this.onSave?.call(colorHex),
                ),
              ).then((reset) => reset ? this.onReset?.call() : null)
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                this.titleWidget ??
                    Text(
                      this.title ?? 'Title',
                      style: Theme.of(context).textTheme.button,
                    ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: this.useDivider ? const BaseDivider() : Container(),
                ),
                Text(
                  this.description ?? 'Title',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 32.0),
          SizedBox(
            width: 75.0,
            child: this.onActiveChanged != null
                ? ThemedCupertinoSwitch(
                    value: this.active!,
                    onChanged: this.onActiveChanged!,
                  )
                : Column(
                    children: [
                      if (this.onButtonPressed != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: BaseButton(
                            text: this.buttonText ?? 'Button',
                            onPressed: this.onButtonPressed,
                          ),
                        ),
                        if (this.onResetButtonPressed != null)
                          SizedBox(
                            width: double.infinity,
                            child: BaseButton(
                              text: this.resetButtonText ?? 'Button',
                              isDestructive: true,
                              onPressed: this.onResetButtonPressed,
                            ),
                          ),
                      ],
                      if (this.onButtonPressed == null) ...[
                        ColorBubble(
                          color:
                              this.colorHex?.hexToColor() ?? Colors.transparent,
                          size: 32.0,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: FittedBox(
                            child: Text(
                              this.colorHex != null
                                  ? '#${this.colorHex}'
                                  : 'Transparent',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          )
        ],
      ),
    );
  }
}
