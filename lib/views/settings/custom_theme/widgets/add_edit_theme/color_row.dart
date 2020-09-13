import 'package:flutter/material.dart';

import '../../../../../types/extensions/string.dart';
import '../../../../../utils/modal_handler.dart';
import '../color_picker/color_picker.dart';

class ColorRow extends StatelessWidget {
  final String colorTitle;
  final String colorDescription;
  final String colorHex;
  final void Function(String) onSave;

  ColorRow({
    @required this.colorTitle,
    @required this.colorDescription,
    @required this.colorHex,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ModalHandler.showBaseBottomSheet(
        context: context,
        modalWidget: Container(
          height: 340.0,
          child: ColorPicker(
            title: this.colorTitle,
            description: this.colorDescription,
            color: this.colorHex,
            onSave: (colorHex) => this.onSave?.call(colorHex),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  this.colorTitle,
                  style: Theme.of(context).textTheme.button,
                ),
                Divider(),
                Text(
                  this.colorDescription,
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
            child: Column(
              children: [
                Container(
                  height: 32.0,
                  width: 32.0,
                  decoration: BoxDecoration(
                    color: this.colorHex.hexToColor(),
                    border: Border.all(
                      color: Colors.black,
                      width: 1.0,
                    ),
                  ),
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
