import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/hidden_scene.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:provider/provider.dart';

import '../../../models/connection.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../types/enums/hive_keys.dart';
import 'widgets/data_block.dart';
import 'widgets/data_entry.dart';

class DataManagementView extends StatelessWidget {
  Future<void> _deleteAll(BuildContext context) async {
    await Hive.box<Connection>(HiveKeys.SavedConnections.name).clear();
    await Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).clear();
    await Hive.box<HiddenScene>(HiveKeys.HiddenSceneItem.name).clear();
    await Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).clear();
    await Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).clear();
    await Hive.box(HiveKeys.Settings.name).clear();

    context.read<TabsStore>().setActiveTab(Tabs.Home);

    Navigator.of(context, rootNavigator: true)
        .pushReplacementNamed(AppRoutingKeys.Intro.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Data Management',
        listViewChildren: [
          DataBlock(
            dataEntries: [
              DataEntry(
                title: 'All Data',
                description:
                    'All the data the app persisted so far including settings set like custom theme, wakelock etc. or any saved connections and so on.',
                customConfirmationText:
                    'Woah chill... you sure? Like I mean all kind of things set like settings or entries added like connections or statistics will be deleted. This is very There is no turning back!',
                additionalConfirmationText:
                    'It seems you are sure about this, right? Well, go ahead... just want to make sure it\'s actually intended! :)',
                onClear: () => _deleteAll(context),
              ),
            ],
          ),
          DataBlock(
            dataEntries: [
              DataEntry(
                title: 'Saved Connections',
                description:
                    'All saved connections which are listed beneath the autodiscover / connect box in the home tab (at least once you saved any connections).',
                onClear: () =>
                    Hive.box<Connection>(HiveKeys.SavedConnections.name)
                        .clear(),
              ),
              DataEntry(
                title: 'Statistics',
                description:
                    'All entries listed in the statistics tab which are created for every live stream OBS Blade is connected to.',
                onClear: () {
                  /// Since the user might be in a detailed statistic view, we pop until
                  /// we are back in the root view
                  context
                      .read<TabsStore>()
                      .navigatorKeys[Tabs.Statistics]
                      ?.currentState
                      ?.popUntil((route) => route.isFirst);

                  Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
                      .clear();
                },
              ),
              DataEntry(
                title: 'Hidden Scenes',
                description:
                    'All scenes that have been hidden in the dashboard of a connected OBS instance.',
                onClear: () =>
                    Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).clear(),
              ),
              DataEntry(
                title: 'Hidden Scene Items',
                description:
                    'All scene items that have been hidden in the dashboard of a connected OBS instance.',
                onClear: () =>
                    Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name)
                        .clear(),
              ),
              DataEntry(
                title: 'Twitch Chats',
                description:
                    'All Twitch usernames that have been added to the stream chat widget in the dashboard.',
                onClear: () {
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.SelectedTwitchUsername.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.TwitchUsernames.name);
                },
              ),
              DataEntry(
                title: 'YouTube Chats',
                description:
                    'All YouTube usernames that have been added to the stream chat widget in the dashboard.',
                onClear: () {
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.SelectedYoutubeUsername.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.YoutubeUsernames.name);
                },
              ),
              DataEntry(
                title: 'Don\'t ask me again Checks',
                description:
                    'All checks set in the dialogs popped up to explain something very important but could get annoying very fast and aren\'t showing up anymore. If you want to see them again - here you go!',
                onClear: () {
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowHidingScenesWarning.name);
                  Hive.box(HiveKeys.Settings.name).delete(
                      SettingsKeys.DontShowHidingSceneItemsWarning.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowPreviewWarning.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowYouTubeChatBetaWarning.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowRecordStartMessage.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowRecordStopMessage.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowStreamStartMessage.name);
                  Hive.box(HiveKeys.Settings.name)
                      .delete(SettingsKeys.DontShowStreamStopMessage.name);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
