import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/general/column_separated.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/built_in_themes.dart';
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
        ? ColumnSeparated(
            useSymmetricOutsidePadding: true,
            additionalPaddingSeparator: const EdgeInsets.only(left: 64.0),
            children: themes.map(
              (theme) => ThemeEntry(
                customTheme: theme,
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
