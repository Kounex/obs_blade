import 'package:flutter/material.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/column_separated.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../utils/built_in_themes.dart';
import 'theme_entry.dart';

class CustomThemeList extends StatelessWidget {
  final bool predefinedThemes;

  const CustomThemeList({super.key, this.predefinedThemes = false});

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<CustomTheme>(
      hiveKey: HiveKeys.CustomTheme,
      builder: (context, customThemeBox, child) {
        Iterable<CustomTheme> themes = this.predefinedThemes
            ? BuiltInThemes.themes
            : customThemeBox.values;

        return themes.isNotEmpty
            ? ColumnSeparated(
                useSymmetricOutsidePadding: true,

                /// Same 24pt inset as the BaseCard header divider (and the
                /// card title), so every divider in the card spans the same
                /// width instead of mixing full-width and deeply indented
                /// separators.
                additionalPaddingSeparator:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  for (final (index, theme) in themes.indexed)
                    StaggeredEntrance(
                      index: index,
                      child: ThemeEntry(
                        customTheme: theme,
                        isEditable: !this.predefinedThemes,
                      ),
                    ),
                ],
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
      },
    );
  }
}
