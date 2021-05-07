import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';

import '../../../models/app_log.dart';
import '../../../models/connection.dart';
import '../../../models/custom_theme.dart';
import '../../../models/enums/log_level.dart';
import '../../../models/hidden_scene.dart';
import '../../../models/hidden_scene_item.dart';
import '../../../models/past_stream_data.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../stores/shared/tabs.dart';
import '../../../types/enums/hive_keys.dart';
import '../../../types/enums/settings_keys.dart';
import '../../../utils/routing_helper.dart';
import 'widgets/data_block.dart';
import 'widgets/data_entry.dart';

class DataManagementView extends StatelessWidget {
  Future<void> _deleteAll(BuildContext context) async {
    await Hive.box<Connection>(HiveKeys.SavedConnections.name).clear();
    await Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).clear();
    await Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).clear();
    await Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).clear();
    await Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).clear();
    await Hive.box<AppLog>(HiveKeys.AppLog.name).clear();
    await Hive.box(HiveKeys.Settings.name).clear();

    GetIt.instance<TabsStore>().setActiveTab(Tabs.Home);

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
                    'Are you sure? Like I mean all kind of things set like settings or entries added like connections or statistics will be deleted. There is no turning back!',
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
                onClear: () {
                  Hive.box<Connection>(HiveKeys.SavedConnections.name).clear();

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All saved connections have been deleted by the user.',
                    null,
                    true,
                  ));
                },
              ),
              DataEntry(
                title: 'Statistics',
                description:
                    'All entries listed in the statistics tab which are created for every live stream OBS Blade is connected to.',
                onClear: () {
                  /// Since the user might be in a detailed statistic view, we pop until
                  /// we are back in the root view
                  GetIt.instance<TabsStore>()
                      .navigatorKeys[Tabs.Statistics]
                      ?.currentState
                      ?.popUntil((route) => route.isFirst);

                  Hive.box<PastStreamData>(HiveKeys.PastStreamData.name)
                      .clear();

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All statistics have been deleted by the user.',
                    null,
                    true,
                  ));
                },
              ),
              DataEntry(
                title: 'Hidden Scenes',
                description:
                    'All scenes that have been hidden in the dashboard of a connected OBS instance.',
                onClear: () {
                  Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).clear();

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All hidden scenes have been deleted by the user.',
                    null,
                    true,
                  ));
                },
              ),
              DataEntry(
                title: 'Hidden Scene Items',
                description:
                    'All scene items that have been hidden in the dashboard of a connected OBS instance.',
                onClear: () {
                  Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name)
                      .clear();

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All hidden scene items have been deleted by the user.',
                    null,
                    true,
                  ));
                },
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

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All twitch chats have been deleted by the user.',
                    null,
                    true,
                  ));
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

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All youtube chats have been deleted by the user.',
                    null,
                    true,
                  ));
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

                  Hive.box<AppLog>(HiveKeys.AppLog.name).add(AppLog(
                    DateTime.now().millisecondsSinceEpoch,
                    LogLevel.Warning,
                    'All don\'t ask me again checks have been deleted by the user.',
                    null,
                    true,
                  ));
                },
              ),
              DataEntry(
                title: 'Logs',
                description:
                    'All log entries found under "Logs" in the settings tab. You can delete them selectively in the logs view!',
                onClear: () => Hive.box<AppLog>(HiveKeys.AppLog.name).clear(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
