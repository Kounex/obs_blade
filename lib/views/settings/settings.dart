import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../shared/general/custom_sliver_list.dart';
import '../../shared/general/hive_builder.dart';
import '../../shared/general/themed/cupertino_sliver_navigation_bar.dart';
import '../../shared/general/themed/cupertino_switch.dart';
import '../../stores/shared/tabs.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/modal_handler.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import 'widgets/action_block.dart/action_block.dart';
import 'widgets/action_block.dart/block_entry.dart';
import 'widgets/support_dialog/support_dialog.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        physics: StylingHelper.platformAwareScrollPhysics,
        slivers: <Widget>[
          const ThemedCupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            builder: (context, settingsBox, child) => CustomSliverList(
              children: [
                ActionBlock(
                  title: 'General',
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.device_phone_portrait,
                      title: 'Wake Lock',
                      help:
                          'This option will keep the screen active while connected to an OBS instance. If you are not connected to an OBS instance, the time set in your phone settings will be used as usual.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.WakeLock.name,
                          defaultValue: true,
                        ),
                        onChanged: (wakeLock) {
                          settingsBox.put(SettingsKeys.WakeLock.name, wakeLock);
                          if (wakeLock) {
                            /// Check if user is currently in the [DashboardView], therefore
                            /// connected to an OBS instance, we will then activate [Wakelock]
                            /// now since otherwise it won't affect the current connection because
                            /// it will only trigger when entereing the [DashboardView]
                            if (GetIt.instance<TabsStore>()
                                    .activeRoutePerNavigator[Tabs.Home] ==
                                HomeTabRoutingKeys.Dashboard.route) {
                              WakelockPlus.enable();
                            }
                          } else {
                            WakelockPlus.disable();
                          }
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.loop,
                      title: 'Unlimited Retries',
                      help:
                          'When active, OBS Blade will try to reconnect to a lost OBS connection indefinitely instead of aborting when reaching a fixed amount of attempts.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.UnlimitedReconnects.name,
                          defaultValue: false,
                        ),
                        onChanged: (unlimitedReconnects) {
                          settingsBox.put(SettingsKeys.UnlimitedReconnects.name,
                              unlimitedReconnects);
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.archivebox_fill,
                      title: 'Data Management',
                      navigateTo: SettingsTabRoutingKeys.DataManagement.route,
                    ),
                  ],
                ),
                ActionBlock(
                  title: 'Dashboard',
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.profile_circled,
                      leadingSize: 30.0,
                      title: 'Profiles',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeProfile.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeProfile) {
                          settingsBox.put(
                            SettingsKeys.ExposeProfile.name,
                            exposeProfile,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.collections_solid,
                      leadingSize: 26.0,
                      title: 'Scene Collections',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeSceneCollection.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeSceneCollection) {
                          settingsBox.put(
                            SettingsKeys.ExposeSceneCollection.name,
                            exposeSceneCollection,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: Icons.live_tv_rounded,
                      leadingSize: 28.0,
                      title: 'Streaming Controls',
                      help:
                          'If active, the streaming actions (start/stop) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeStreamingControls.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeStreamingControls) {
                          settingsBox.put(
                            SettingsKeys.ExposeStreamingControls.name,
                            exposeStreamingControls,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.recordingtape,
                      leadingSize: 30.0,
                      title: 'Recording Controls',
                      help:
                          'If active, the recording actions (start/stop/pause) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeRecordingControls.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeRecordingControls) {
                          settingsBox.put(
                            SettingsKeys.ExposeRecordingControls.name,
                            exposeRecordingControls,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.reply_thick_solid,
                      leadingSize: 28.0,
                      title: 'Replay Controls',
                      help:
                          'If active, the replay buffer actions (start/stop/save) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeReplayBufferControls.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeReplayBufferControls) {
                          settingsBox.put(
                            SettingsKeys.ExposeReplayBufferControls.name,
                            exposeReplayBufferControls,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.square_grid_3x2_fill,
                      leadingSize: 28.0,
                      title: 'Hotkeys',
                      help:
                          'If active, the hotkey button will be added to the dashboard which enables you to list all available OBS hotkeys and trigger them. Enables more precise interaction with OBS, usually only needed for power users.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeHotkeys.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeHotkeys) {
                          settingsBox.put(
                            SettingsKeys.ExposeHotkeys.name,
                            exposeHotkeys,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.film,
                      leadingSize: 26.0,
                      title: 'Studio Mode',
                      help:
                          'Enables the awareness and usage of the Studio Mode in OBS Blade. Will expose additional settings / buttons in the dashboard.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.ExposeStudioControls.name,
                          defaultValue: false,
                        ),
                        onChanged: (exposeStudioControls) {
                          settingsBox.put(
                            SettingsKeys.ExposeStudioControls.name,
                            exposeStudioControls,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.person_2_square_stack,
                      leadingSize: 30.0,
                      title: 'Scene Preview',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                            SettingsKeys.ExposeScenePreview.name,
                            defaultValue: true),
                        onChanged: (exposeScenePreview) {
                          settingsBox.put(
                            SettingsKeys.ExposeScenePreview.name,
                            exposeScenePreview,
                          );
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.lock_fill,
                      leadingSize: 30.0,
                      title: 'Force Tablet Mode',
                      help:
                          'Elements in the Dashboard View will be displayed next to each other instead of being in tabs if the screen is big enough. If you want to you can set this manually.\n\nCAUTION: Will probably not fit your screen.',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                            SettingsKeys.EnforceTabletMode.name,
                            defaultValue: false),
                        onChanged: (enforceTabletMode) {
                          settingsBox.put(
                            SettingsKeys.EnforceTabletMode.name,
                            enforceTabletMode,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                ActionBlock(
                  title: 'Theme',
                  blockEntries: [
                    BlockEntry(
                        leading: CupertinoIcons.lab_flask_solid,
                        title: 'Custom Theme',
                        navigateTo: SettingsTabRoutingKeys.CustomTheme.route,
                        navigateToResult: Text(
                          settingsBox.get(SettingsKeys.CustomTheme.name,
                                  defaultValue: false)
                              ? 'Active'
                              : 'Inactive',
                        )),
                    BlockEntry(
                      leading: CupertinoIcons.moon_circle_fill,
                      leadingSize: 30.0,
                      title: 'True Dark Mode',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                          SettingsKeys.TrueDark.name,
                          defaultValue: false,
                        ),
                        enabled: !settingsBox.get(
                          SettingsKeys.CustomTheme.name,
                          defaultValue: false,
                        ),
                        disabledChangeInfo:
                            'This setting has no effect and can\'t be changed while Custom Theme is active',
                        onChanged: (trueDark) {
                          settingsBox.put(
                            SettingsKeys.TrueDark.name,
                            trueDark,
                          );
                        },
                      ),
                    ),
                    if (settingsBox.get(SettingsKeys.TrueDark.name,
                        defaultValue: false))
                      BlockEntry(
                        leading: CupertinoIcons.drop_fill,
                        title: 'Reduce Smearing',
                        help:
                            'Only relevant for OLED displays. Using a fully black background might cause smearing while scrolling so this option will apply a slightly lighter background color.\n\nCAUTION: Might drain "more" battery.',
                        trailing: ThemedCupertinoSwitch(
                          value: settingsBox.get(
                            SettingsKeys.ReduceSmearing.name,
                            defaultValue: false,
                          ),
                          enabled: !settingsBox.get(
                            SettingsKeys.CustomTheme.name,
                            defaultValue: false,
                          ),
                          disabledChangeInfo:
                              'This setting has no effect and can\'t be changed while Custom Theme is active',
                          onChanged: (reduceSmearing) {
                            settingsBox.put(
                              SettingsKeys.ReduceSmearing.name,
                              reduceSmearing,
                            );
                          },
                        ),
                      ),
                  ],
                ),
                ActionBlock(
                  title: 'Misc.',
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.info_circle_fill,
                      title: 'About',
                      navigateTo: SettingsTabRoutingKeys.About.route,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.chat_bubble_text_fill,
                      title: 'FAQ | Help',
                      navigateTo: SettingsTabRoutingKeys.FAQ.route,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.book_fill,
                      title: 'Intro Slides',
                      navigateTo: AppRoutingKeys.Intro.route,
                      rootNavigation: true,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.doc_person_fill,
                      title: 'Privacy Policy',
                      navigateTo: SettingsTabRoutingKeys.PrivacyPolicy.route,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.square_list_fill,
                      title: 'Logs',
                      navigateTo: SettingsTabRoutingKeys.Logs.route,
                    ),
                  ],
                ),
                ActionBlock(
                  title: 'Support',
                  descriptionWidget: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      return Row(
                        children: [
                          Text(
                            'Version ',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (snapshot.hasData)
                            Text(
                              snapshot.data!.version,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      );
                    },
                  ),
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.hammer_fill,
                      title: 'Blacksmith',
                      navigateToResult: Text(
                        (settingsBox.get(SettingsKeys.BoughtBlacksmith.name,
                                defaultValue: false) as bool)
                            ? 'Active'
                            : 'Inactive',
                      ),
                      onTap: () => ModalHandler.showBaseDialog(
                        context: context,
                        barrierDismissible: true,
                        dialogWidget: const SupportDialog(
                          title: 'Blacksmith',
                          icon: CupertinoIcons.hammer_fill,
                          type: SupportType.Blacksmith,
                        ),
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.gift_fill,
                      title: 'Tip Jar',
                      onTap: () => ModalHandler.showBaseDialog(
                        context: context,
                        barrierDismissible: true,
                        dialogWidget: const SupportDialog(
                          title: 'Tips',
                          icon: CupertinoIcons.gift_fill,
                          type: SupportType.Tips,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
