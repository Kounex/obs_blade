import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../shared/general/themed/themed_cupertino_scaffold.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../shared/overlay/base_result.dart';
import '../../../utils/modal_handler.dart';
import 'widgets/add_edit_theme/add_edit_theme.dart';
import 'widgets/custom_theme_list/custom_theme_list.dart';
import 'widgets/theme_active/theme_active.dart';

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
      body: ValueListenableBuilder(
        valueListenable: Hive.box(HiveKeys.Settings.name).listenable(
          keys: [
            SettingsKeys.ActiveCustomThemeUUID.name,
          ],
        ),
        builder: (context, Box settingsBox, child) =>
            TransculentCupertinoNavBarWrapper(
          previousTitle: 'Settings',
          title: 'Custom Theme',
          listViewChildren: [
            BaseCard(
              bottomPadding: 12.0,
              child: ThemeActive(),
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
                    onPressed: () => ModalHandler.showBaseCupertinoBottomSheet(
                      context: context,
                      modalWidgetBuilder: (context, scrollController) =>
                          AddEditTheme(
                        scrollController: scrollController,
                      ),
                    ),
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
