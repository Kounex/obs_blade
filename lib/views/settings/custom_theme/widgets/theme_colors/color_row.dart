import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../types/enums/settings_keys.dart';
import '../../../../../types/extensions/color.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';
import '../../../../../types/extensions/string.dart';
import '../color_picker/color_picker.dart';

class ColorRow extends StatelessWidget {
  final Box settingsBox;
  final SettingsKeys colorKey;

  ColorRow({@required this.settingsBox, @required this.colorKey});

  @override
  Widget build(BuildContext context) {
    String color = settingsBox.get(
      this.colorKey.name,
      defaultValue: StylingHelper.MAIN_BLUE.toHex(),
    );

    return GestureDetector(
      onTap: () => ModalHandler.showBaseBottomSheet(
        context: context,
        modalWidget: Container(
          height: 300.0,
          child: ColorPicker(
            title: 'Primary Color',
            color: color,
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
                  'Primary Color',
                  style: Theme.of(context).textTheme.button,
                ),
                Divider(),
                Text(
                  'Main color which is used for the AppBar, BottomBar, Cards, etc.',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50.0,
          ),
          Column(
            children: [
              Container(
                height: 32.0,
                width: 32.0,
                decoration: BoxDecoration(
                  color: color.hexToColor(),
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text('#$color'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
