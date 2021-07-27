import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/general/base/base_card.dart';
import '../../../shared/general/clean_list_tile.dart';
import '../../../shared/general/hive_builder.dart';
import '../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../shared/general/themed/themed_cupertino_scaffold.dart';
import '../../../shared/general/themed/themed_cupertino_switch.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../shared/overlay/base_result.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import 'widgets/custom_theme_list/custom_theme_list.dart';

class CustomThemeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      /// I need to use the [ValueListenableBuilder] here since this subtree
      /// doesn't get rebuilded when [MaterialApp] rebuilds (there is a
      /// [ValueListenableBuilder] wrapping [MaterialApp] which also listenes
      /// to [SettingsKeys.ActiveCustomThemeUUID]) so changing and updating
      /// the current theme works but this subtree doesn't get rebuilded
      /// in this process - need to investigate the precise reason for that
      /// since I assumed this part would get rebuilded as well
      body: HiveBuilder<dynamic>(
        hiveKey: HiveKeys.Settings,
        rebuildKeys: [
          SettingsKeys.ActiveCustomThemeUUID,
          SettingsKeys.CustomTheme
        ],
        builder: (context, settingsBox, child) =>
            TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'Custom Theme',
          listViewChildren: [
            BaseCard(
              bottomPadding: 12.0,
              child: CleanListTile(
                title: 'Use Custom Theme',
                description:
                    'Once active the selected theme below will be used for this app. Select between predefined themes or your own!',
                trailing: ThemedCupertinoSwitch(
                  value: settingsBox.get(SettingsKeys.CustomTheme.name,
                      defaultValue: false),
                  onChanged: (customTheme) => settingsBox.put(
                    SettingsKeys.CustomTheme.name,
                    customTheme,
                  ),
                ),
              ),
            ),
            BaseCard(
              title: 'Predefined Themes',
              bottomPadding: 12.0,
              paddingChild: EdgeInsets.all(0),
              child: CustomThemeList(
                predefinedThemes: true,
              ),
            ),
            Stack(
              fit: StackFit.loose,
              alignment: Alignment.bottomCenter,
              children: [
                BaseCard(
                  title: 'Your Themes',
                  trailingTitleWidget: ThemedCupertinoButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      // ModalHandler.showBaseCupertinoBottomSheet(
                      //   context: context,
                      //   modalWidgetBuilder: (context, scrollController) =>
                      //       AddEditTheme(
                      //     scrollController: scrollController,
                      //   ),
                      // );
                    },
                    text: 'Add Theme',
                  ),
                  bottomPadding: 12.0,
                  paddingChild: EdgeInsets.all(0),
                  child: CustomThemeList(),
                ),
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1.25, sigmaY: 1.25),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: BaseCard(
                          paintBorder: true,
                          child: BaseResult(
                            icon: BaseResultIcon.Missing,
                            text: 'Available soon...',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
