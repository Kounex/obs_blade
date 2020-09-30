import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/built_in_themes.dart';
import '../../../widgets/action_block.dart/light_divider.dart';
import 'theme_entry.dart';

class CustomThemeList extends StatelessWidget {
  final bool predefinedThemes;

  CustomThemeList({this.predefinedThemes = false});

  @override
  Widget build(BuildContext context) {
    Iterable<CustomTheme> themes = this.predefinedThemes
        ? BuiltInThemes.themes
        : Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).values;

    return themes.isNotEmpty
        ?

        /// Even though I'm not making use of the actual [ListView]
        /// since i don't want scrolling here, the builder is fitting
        /// for this use case since we can make use of the .separated
        /// constructor to easily add [Divider] here between the entries
        ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.all(0),
            physics: NeverScrollableScrollPhysics(),
            itemCount: themes.length,
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(left: 64.0),
              child: LightDivider(),
            ),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ThemeEntry(
                customTheme: themes.elementAt(index),
                isEditable: !this.predefinedThemes,
              ),
            ),
          )
        : Align(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: BaseResult(
                icon: BaseResultIcon.Missing,
                iconSize: 42.0,
                text: this.predefinedThemes
                    ? 'No predefined themes available!'
                    : 'No custom themes created yet!',
              ),
            ),
          );
  }
}
