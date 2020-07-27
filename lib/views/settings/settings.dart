import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:package_info/package_info.dart';

import '../../models/settings.dart';
import '../../shared/general/themed_cupertino_switch.dart';
import '../../types/enums/hive_keys.dart';
import '../../utils/routing_helper.dart';
import '../../utils/styling_helper.dart';
import '../about/widgets/license_modal.dart';
import 'widgets/action_block.dart/action_block.dart';
import 'widgets/action_block.dart/block_entry.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: StylingHelper.platformAwareScrollPhysics,
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text('Settings'),
          ),
          ValueListenableBuilder(
            valueListenable:
                Hive.box<Settings>(HiveKeys.Settings.name).listenable(),
            builder: (context, Box<Settings> settingsBox, child) => SliverList(
              delegate: SliverChildListDelegate(
                [
                  ActionBlock(
                    title: 'Theme',
                    blockEntries: [
                      BlockEntry(
                        leading: StylingHelper.CUPERTINO_SUNGLASSES_ICON,
                        title: 'True Dark Mode',
                        trailing: ThemedCupertinoSwitch(
                          value: settingsBox.get(0).trueDark ?? false,
                          activeColor: StylingHelper.MAIN_RED,
                          onChanged: (trueDark) {
                            settingsBox.get(0).trueDark = trueDark;
                            settingsBox.get(0).save();
                          },
                        ),
                      ),
                      if (settingsBox.get(0).trueDark)
                        BlockEntry(
                          leading: Icons.opacity,
                          title: 'Reduce smearing',
                          help:
                              'Only relevant for OLED displays. Using a fully black background might cause smearing while scrolling so this option will apply a slightly lighter background color.\n\nMight drain more battery though!',
                          trailing: ThemedCupertinoSwitch(
                            value: settingsBox.get(0).reduceSmearing ?? false,
                            activeColor: StylingHelper.MAIN_RED,
                            onChanged: (reduceSmearing) {
                              settingsBox.get(0).reduceSmearing =
                                  reduceSmearing;
                              settingsBox.get(0).save();
                            },
                          ),
                        ),
                    ],
                  ),
                  ActionBlock(
                    title: 'Layout',
                    blockEntries: [
                      BlockEntry(
                        leading: CupertinoIcons.padlock,
                        title: 'Enforce Tablet Mode',
                        help:
                            'Elements in the Dashboard View will be displayed next to each other instead of being in tabs if the screen is big enough.\n\nIf you want to you can set this manually.\n\nCAUTION: Might not fit your screen!',
                        trailing: ThemedCupertinoSwitch(
                          value: settingsBox.get(0).enforceTabletMode ?? false,
                          activeColor: StylingHelper.MAIN_RED,
                          onChanged: (enforceTabletMode) {
                            settingsBox.get(0).enforceTabletMode =
                                enforceTabletMode;
                            settingsBox.get(0).save();
                          },
                        ),
                      ),
                    ],
                  ),
                  ActionBlock(
                    title: 'Misc.',
                    blockEntries: [
                      BlockEntry(
                        leading: CupertinoIcons.book,
                        title: 'Privacy Policy',
                        navigateTo: SettingsTabRoutingKeys.PrivacyPolicy.route,
                      ),
                      BlockEntry(
                        leading: StylingHelper.CUPERTINO_AT_ICON,
                        title: 'About',
                        onTap: () => showCupertinoModalBottomSheet(
                          expand: true,
                          context: context,
                          backgroundColor: Colors.transparent,
                          useRootNavigator: true,
                          builder: (context, scrollController) =>
                              LicenseModal(),
                        ),
                        // navigateTo: SettingsTabRoutingKeys.About.route,
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
                                snapshot.data.version,
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
          ),
        ],
      ),
    );
  }
}
