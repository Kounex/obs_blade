import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/shared/general/custom_sliver_list.dart';
import 'package:obs_blade/shared/general/themed/themed_cupertino_sliver_navigation_bar.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

import '../../shared/general/themed/themed_cupertino_switch.dart';
import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import 'widgets/action_block.dart/action_block.dart';
import 'widgets/action_block.dart/block_entry.dart';
import 'widgets/support_dialog/support_dialog.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller:
            ModalRoute.of(context)!.settings.arguments as ScrollController,
        physics: StylingHelper.platformAwareScrollPhysics,
        slivers: <Widget>[
          ThemedCupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          ValueListenableBuilder(
            valueListenable: Hive.box(HiveKeys.Settings.name).listenable(),
            builder: (context, Box settingsBox, child) => CustomSliverList(
              children: [
                ActionBlock(
                  title: 'General',
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.device_phone_portrait,
                      title: 'Wake Lock',
                      help:
                          'This option will keep the screen active while connected to an OBS instance. If you are not connected to an OBS instance, the time set in your phone settings will be used as usual!',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(SettingsKeys.WakeLock.name,
                            defaultValue: true),
                        onChanged: (wakeLock) {
                          settingsBox.put(SettingsKeys.WakeLock.name, wakeLock);
                          if (wakeLock) {
                            /// Check if user is currently in the [DashboardView], therefore
                            /// connected to an OBS instance, we will then activate [Wakelock]
                            /// now since otherwise it won't affect the current connection because
                            /// it will only trigger when entereing the [DashboardView]
                            if (context
                                    .read<TabsStore>()
                                    .activeRoutePerNavigator[Tabs.Home] ==
                                HomeTabRoutingKeys.Dashboard.route) {
                              Wakelock.enable();
                            }
                          } else {
                            Wakelock.disable();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                ActionBlock(
                  title: 'DASHBOARD',
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.recordingtape,
                      leadingSize: 30.0,
                      title: 'Recording Controls',
                      help:
                          'If active, the recording actions (start/stop/pause) will be exposed in the dashboard view rather than in the action menu of the app bar. Makes it more accessible!',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                            SettingsKeys.ExposeRecordingControls.name,
                            defaultValue: false),
                        onChanged: (exposeRecordingControls) {
                          settingsBox.put(
                              SettingsKeys.ExposeRecordingControls.name,
                              exposeRecordingControls);
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.film,
                      leadingSize: 30.0,
                      title: 'Studio Mode Support',
                      help:
                          'Enables the awareness and usage of the Studio Mode in OBS Blade. Will expose additional settings / buttons in the dashboard!',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                            SettingsKeys.ExposeStudioControls.name,
                            defaultValue: false),
                        onChanged: (exposeStudioControls) {
                          settingsBox.put(
                              SettingsKeys.ExposeStudioControls.name,
                              exposeStudioControls);
                        },
                      ),
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.lock_fill,
                      leadingSize: 30.0,
                      title: 'Enforce Tablet Mode',
                      help:
                          'Elements in the Dashboard View will be displayed next to each other instead of being in tabs if the screen is big enough. If you want to you can set this manually.\n\nCAUTION: Will probably not fit your screen!',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(
                            SettingsKeys.EnforceTabletMode.name,
                            defaultValue: false),
                        onChanged: (enforceTabletMode) {
                          settingsBox.put(SettingsKeys.EnforceTabletMode.name,
                              enforceTabletMode);
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
                      navigateToResult: settingsBox.get(
                              SettingsKeys.CustomTheme.name,
                              defaultValue: false)
                          ? 'Active'
                          : 'Inactive',
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.moon_circle_fill,
                      leadingSize: 30.0,
                      title: 'True Dark Mode',
                      trailing: ThemedCupertinoSwitch(
                        value: settingsBox.get(SettingsKeys.TrueDark.name,
                            defaultValue: false),
                        onChanged: (trueDark) {
                          settingsBox.put(SettingsKeys.TrueDark.name, trueDark);
                        },
                      ),
                    ),
                    if (settingsBox.get(SettingsKeys.TrueDark.name,
                        defaultValue: false))
                      BlockEntry(
                        leading: CupertinoIcons.drop_fill,
                        title: 'Reduce Smearing',
                        help:
                            'Only relevant for OLED displays. Using a fully black background might cause smearing while scrolling so this option will apply a slightly lighter background color.\n\nCAUTION: Might drain "more" battery!',
                        trailing: ThemedCupertinoSwitch(
                          value: settingsBox.get(
                              SettingsKeys.ReduceSmearing.name,
                              defaultValue: false),
                          onChanged: (reduceSmearing) {
                            settingsBox.put(SettingsKeys.ReduceSmearing.name,
                                reduceSmearing);
                          },
                        ),
                      ),
                  ],
                ),
                ActionBlock(
                  title: 'Misc.',
                  blockEntries: [
                    BlockEntry(
                      leading: CupertinoIcons.book_fill,
                      title: 'Intro Slides',
                      navigateTo: AppRoutingKeys.Intro.route,
                      rootNavigation: true,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.info_circle_fill,
                      title: 'About',
                      navigateTo: SettingsTabRoutingKeys.About.route,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.doc_person_fill,
                      title: 'Privacy Policy',
                      navigateTo: SettingsTabRoutingKeys.PrivacyPolicy.route,
                    ),
                    BlockEntry(
                      leading: CupertinoIcons.heart_solid,
                      title: 'Support Me',
                      heroPlaceholder: CupertinoIcons.heart,
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).push(
                        PageRouteBuilder(
                          opaque: false,
                          barrierDismissible: true,
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) =>
                                  DecoratedBoxTransition(
                            decoration: DecorationTween(
                              begin: BoxDecoration(color: Colors.transparent),
                              end: BoxDecoration(color: Colors.black54),
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          ),
                          pageBuilder: (BuildContext context, _, __) =>
                              SupportDialog(),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 7.0, left: 14.0),
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      return Row(
                        children: [
                          Text(
                            'Version ',
                            style: Theme.of(context).textTheme.caption,
                          ),
                          if (snapshot.hasData)
                            Text(
                              snapshot.data!.version,
                              style: Theme.of(context).textTheme.caption,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
