import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/base_button.dart';
import 'package:obs_blade/shared/general/themed/themed_cupertino_switch.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_bubble.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';

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

  final void Function(String)? onSave;

  ThemeRow({
    this.title,
    this.titleWidget,
    this.description,
    this.colorHex,
    this.useDivider = true,
    this.active,
    this.onActiveChanged,
    this.buttonText,
    this.onButtonPressed,
    this.onSave,
  });

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
              )
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
                  child: this.useDivider ? LightDivider() : Container(),
                ),
                Text(
                  this.description ?? 'Title',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
          SizedBox(width: 32.0),
          SizedBox(
            width: 75.0,
            child: this.onActiveChanged != null
                ? ThemedCupertinoSwitch(
                    value: this.active!,
                    onChanged: this.onActiveChanged!,
                  )
                : this.onButtonPressed != null
                    ? BaseButton(
                        text: this.buttonText ?? 'Button',
                        onPressed: this.onButtonPressed,
                      )
                    : Column(
                        children: [
                          ColorBubble(
                            color: this.colorHex!.hexToColor(),
                            size: 32.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text('#${this.colorHex}'),
                          ),
                        ],
                      ),
          )
        ],
      ),
    );
  }
}
