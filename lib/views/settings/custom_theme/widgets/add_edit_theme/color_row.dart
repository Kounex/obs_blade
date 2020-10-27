import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/themed/themed_cupertino_switch.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_bubble.dart';

import '../../../../../types/extensions/string.dart';
import '../../../../../utils/modal_handler.dart';
import '../color_picker/color_picker.dart';

class ColorRow extends StatelessWidget {
  final String title;
  final String description;
  final String colorHex;

  final bool active;
  final void Function(bool) onActiveChanged;

  final void Function(String) onSave;

  ColorRow({
    @required this.title,
    @required this.description,
    @required this.colorHex,
    this.active,
    this.onActiveChanged,
    this.onSave,
  }) : assert((onActiveChanged == null && onSave == null) ||
            (onActiveChanged == null && onSave != null) ||
            (onActiveChanged != null && active != null && onSave == null));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: this.onSave != null
          ? () => ModalHandler.showBaseBottomSheet(
                context: context,
                modalWidget: ColorPicker(
                  title: this.title,
                  description: this.description,
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
                Text(
                  this.title,
                  style: Theme.of(context).textTheme.button,
                ),
                Divider(),
                Text(
                  this.description,
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32.0,
          ),
          SizedBox(
            width: 75.0,
            child: this.onActiveChanged != null
                ? ThemedCupertinoSwitch(
                    value: this.active,
                    onChanged: this.onActiveChanged,
                  )
                : Column(
                    children: [
                      ColorBubble(
                        color: this.colorHex.hexToColor(),
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
