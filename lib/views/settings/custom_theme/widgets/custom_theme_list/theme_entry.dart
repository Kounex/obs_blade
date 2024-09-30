import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../../models/custom_theme.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/general/themed/cupertino_button.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../add_edit_theme/add_edit_theme.dart';
import 'theme_colors_row.dart';

class ThemeEntry extends StatelessWidget {
  final CustomTheme customTheme;
  final bool isEditable;

  const ThemeEntry(
      {super.key, required this.customTheme, this.isEditable = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Hive.box(HiveKeys.Settings.name).put(
        SettingsKeys.ActiveCustomThemeUUID.name,
        this.customTheme.uuid,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 64.0,
                  child: HiveBuilder<dynamic>(
                    hiveKey: HiveKeys.Settings,
                    rebuildKeys: const [SettingsKeys.ActiveCustomThemeUUID],
                    builder: (context, settingsBox, child) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      ),
                      child: settingsBox.get(
                                  SettingsKeys.ActiveCustomThemeUUID.name,
                                  defaultValue: '') ==
                              this.customTheme.uuid
                          ? Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 32.0,
                              color: Theme.of(context).colorScheme.secondary,
                            )
                          : Container(),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: !this.isEditable ? 24.0 : 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          this.customTheme.name ?? 'Unnamed theme',
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (this.customTheme.description != null &&
                            this.customTheme.description!.isNotEmpty) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            this.customTheme.description!,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 8.0),
                        ThemeColorsRow(customTheme: this.customTheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (this.isEditable)
            ThemedCupertinoButton(
              padding: const EdgeInsets.only(right: 24.0),
              text: 'Edit',
              onPressed: () => ModalHandler.showBaseCupertinoBottomSheet(
                context: context,
                modalWidgetBuilder: (context, scrollController) => AddEditTheme(
                  customTheme: this.customTheme,
                  scrollController: scrollController,
                ),
              ),
            )
        ],
      ),
    );
  }
}
