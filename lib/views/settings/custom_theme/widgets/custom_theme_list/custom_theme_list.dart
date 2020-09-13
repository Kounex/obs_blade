import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import '../add_edit_theme/add_edit_theme.dart';
import 'theme_colors_row.dart';

class CustomThemeList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).listenable(),
      builder: (context, Box<CustomTheme> customThemeBox, child) =>
          customThemeBox.values.isNotEmpty
              ? ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: customThemeBox.values.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: LightDivider(),
                  ),
                  itemBuilder: (context, index) => ListTile(
                    onTap: () => ModalHandler.showBaseCupertinoBottomSheet(
                      context: context,
                      modalWidgetBuilder: (context, scrollController) =>
                          AddEditTheme(
                        customTheme: customThemeBox.values.elementAt(index),
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customThemeBox.values.elementAt(index).name ??
                            'Unnamed theme'),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: ThemeColorsRow(
                            customTheme: customThemeBox.values.elementAt(index),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      customThemeBox.values.elementAt(index).description ??
                          'No description',
                    ),
                  ),
                )
              : Align(
                  child: BaseResult(
                    icon: BaseResultIcon.Missing,
                    iconSize: 42.0,
                    text: 'No custom theme created yet!',
                  ),
                ),
    );
  }
}
