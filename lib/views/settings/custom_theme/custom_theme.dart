import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/adaptive_switch.dart';
import '../../../shared/general/base/card.dart';
import '../../../shared/general/clean_list_tile.dart';
import '../../../shared/general/hive_builder.dart';
import '../../../shared/general/themed/cupertino_button.dart';
import '../../../shared/general/themed/cupertino_scaffold.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../stores/pro_store.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../../../utils/built_in_themes.dart';
import '../../../utils/modal_handler.dart';
import '../../../utils/routing_helper.dart';
import 'widgets/add_edit_theme/add_edit_theme.dart';
import 'widgets/custom_theme_list/custom_theme_list.dart';

/// Custom themes are unlocked for legacy blacksmith owners (offline-
/// friendly Hive flag — blacksmith is no longer sold but its restore path
/// is kept) and for Pro ([ProStore.isPro], live mid-session). Blacksmith
/// is intentionally NOT folded into the Pro entitlement — the two unlocks
/// stand alone.
@visibleForTesting
bool customThemesUnlocked(Box<dynamic> settingsBox, {ProStore? proStore}) =>
    (settingsBox.get(SettingsKeys.BoughtBlacksmith.name, defaultValue: false)
        as bool) ||
    (proStore ?? GetIt.instance<ProStore>()).isPro;

class CustomThemeView extends StatefulWidget {
  const CustomThemeView({
    super.key,
  });

  @override
  State<CustomThemeView> createState() => _CustomThemeViewState();
}

class _CustomThemeViewState extends State<CustomThemeView> {
  void _openAddTheme(BuildContext context, {required bool unlocked}) {
    if (unlocked) {
      ModalHandler.showBaseCupertinoBottomSheet(
        context: context,
        modalWidgetBuilder: (context, scrollController) => AddEditTheme(
          scrollController: scrollController,
        ),
      );
    } else {
      /// Blacksmith is no longer sold — the upsell is the Pro paywall.
      Navigator.of(context).pushNamed(SettingsTabRoutingKeys.Pro.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedCupertinoScaffold(
      /// I need to use the [ValueListenableBuilder] here since this subtree
      /// doesn't get rebuilded when [MaterialApp] rebuilds (there is a
      /// [ValueListenableBuilder] wrapping [MaterialApp] which also listenes
      /// to [SettingsKeys.ActiveCustomThemeUUID]) so changing and updating
      /// the current theme works but this subtree doesn't get rebuilded
      /// in this process since it's a [StatefulWidget] and the state itself
      /// is not being rebuild (would have to trigger this specifically with keys
      /// or overriding updateWidget or similar)
      body: HiveBuilder<dynamic>(
        hiveKey: HiveKeys.Settings,
        rebuildKeys: const [
          SettingsKeys.ActiveCustomThemeUUID,
          SettingsKeys.CustomTheme,
          SettingsKeys.BoughtBlacksmith
        ],
        builder: (context, settingsBox, child) {
          /// Explicit [AnimatedTheme] on the activation surface: the
          /// MaterialApp subtree is not keyed, so its implicit crossfade
          /// already plays app-wide - this re-wraps the editor itself so
          /// the screen the user activates the theme on visibly morphs at
          /// the design system's theme-change duration ([AppMotion.slow])
          /// instead of the shorter framework default.
          return AnimatedTheme(
            data: Theme.of(context),
            duration: AppMotion.slow,
            curve: AppMotion.standard,
            child: TransculentCupertinoNavBarWrapper(
              previousTitle: 'Settings',
              title: 'Custom Theme',
              listViewChildren: [
                StaggeredEntrance(
                  index: 0,
                  child: BaseCard(
                    bottomPadding: 12.0,
                    child: CleanListTile(
                      title: 'Use Custom Theme',
                      description:
                          'Once active the selected theme below will be used for this app. Choose one of the predefined themes or your own!',
                      trailing: BaseAdaptiveSwitch(
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
                ),
                const StaggeredEntrance(
                  index: 1,
                  child: BaseCard(
                    title: 'Predefined Themes',
                    bottomPadding: 12.0,
                    paddingChild: EdgeInsets.all(0),
                    child: CustomThemeList(
                      predefinedThemes: true,
                    ),
                  ),
                ),
                StaggeredEntrance(
                  index: 2,
                  child: BaseCard(
                    title: 'Your Themes',
                    trailingTitleWidget: ThemedCupertinoButton(
                      text: 'Add Theme',
                      padding: const EdgeInsets.all(0),

                      /// Evaluated at tap time (not at build), so the gate
                      /// picks up a mid-session Pro purchase / blacksmith
                      /// restore without a rebuild.
                      onPressed: () => _openAddTheme(
                        context,
                        unlocked: customThemesUnlocked(settingsBox),
                      ),
                    ),
                    bottomPadding: 12.0,
                    paddingChild: const EdgeInsets.all(0),
                    child: const CustomThemeList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
