import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/purchases.dart';
import 'package:obs_blade/utils/built_in_themes.dart';
import 'package:obs_blade/views/settings/widgets/blacksmith_dialog.dart';

import '../../../shared/general/base/card.dart';
import '../../../shared/general/clean_list_tile.dart';
import '../../../shared/general/hive_builder.dart';
import '../../../shared/general/themed/cupertino_button.dart';
import '../../../shared/general/themed/cupertino_scaffold.dart';
import '../../../shared/general/themed/cupertino_switch.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../../../utils/modal_handler.dart';
import 'widgets/add_edit_theme/add_edit_theme.dart';
import 'widgets/custom_theme_list/custom_theme_list.dart';

class CustomThemeView extends StatefulWidget {
  const CustomThemeView({Key? key}) : super(key: key);

  @override
  State<CustomThemeView> createState() => _CustomThemeViewState();
}

class _CustomThemeViewState extends State<CustomThemeView> {
  bool _fromBlacksmithDialog = false;

  void _openAddTheme(BuildContext context) {
    GetIt.instance<PurchasesStore>()
            .purchases
            .any((purchase) => purchase.productID == 'blacksmith')
        ? ModalHandler.showBaseCupertinoBottomSheet(
            context: context,
            modalWidgetBuilder: (context, scrollController) => AddEditTheme(
              scrollController: scrollController,
            ),
          )
        : ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: const BlacksmithDialog(),
          ).then(
            (value) => _openAddTheme(context),
          );
  }

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
        rebuildKeys: const [
          SettingsKeys.ActiveCustomThemeUUID,
          SettingsKeys.CustomTheme
        ],
        builder: (context, settingsBox, child) {
          bool? openAddTheme = (ModalRoute.of(context)?.settings.arguments
              as Map?)?['blacksmith'];
          if (openAddTheme != null && openAddTheme && !_fromBlacksmithDialog) {
            _fromBlacksmithDialog = true;
            Future.delayed(const Duration(milliseconds: 500),
                () => _openAddTheme(context));
          }

          return TransculentCupertinoNavBarWrapper(
            previousTitle: 'Settings',
            title: 'Custom Theme',
            listViewChildren: [
              BaseCard(
                bottomPadding: 12.0,
                child: CleanListTile(
                  title: 'Use Custom Theme',
                  description:
                      'Once active the selected theme below will be used for this app. Choose one of the predefined themes or your own!',
                  trailing: ThemedCupertinoSwitch(
                    value: settingsBox.get(SettingsKeys.CustomTheme.name,
                        defaultValue: false),
                    onChanged: (customTheme) {
                      settingsBox.put(
                        SettingsKeys.CustomTheme.name,
                        customTheme,
                      );
                      if ((settingsBox.get(
                              SettingsKeys.ActiveCustomThemeUUID.name,
                              defaultValue: '') as String)
                          .isEmpty) {
                        settingsBox.put(
                          SettingsKeys.ActiveCustomThemeUUID.name,
                          BuiltInThemes.themes.first.uuid,
                        );
                      }
                    },
                  ),
                ),
              ),
              const BaseCard(
                title: 'Predefined Themes',
                bottomPadding: 12.0,
                paddingChild: EdgeInsets.all(0),
                child: CustomThemeList(
                  predefinedThemes: true,
                ),
              ),
              BaseCard(
                title: 'Your Themes',
                trailingTitleWidget: ThemedCupertinoButton(
                  padding: const EdgeInsets.all(0),
                  onPressed: () => _openAddTheme(context),
                  text: 'Add Theme',
                ),
                bottomPadding: 12.0,
                paddingChild: const EdgeInsets.all(0),
                child: const CustomThemeList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
