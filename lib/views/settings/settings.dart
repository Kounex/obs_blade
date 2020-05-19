import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/models/settings.dart';
import 'package:obs_station/types/enums/hive_keys.dart';
import 'package:obs_station/utils/routing_helper.dart';
import 'package:obs_station/utils/styling_helper.dart';
import 'package:obs_station/views/settings/widgets/action_block.dart/action_block.dart';
import 'package:obs_station/views/settings/widgets/action_block.dart/block_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            title: Text('Settings'),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                ValueListenableBuilder(
                  valueListenable:
                      Hive.box<Settings>(HiveKeys.SETTINGS.name).listenable(),
                  builder: (context, Box<Settings> settingsBox, child) =>
                      ActionBlock(
                    blockEntries: [
                      BlockEntry(
                        leading: StylingHelper.CUPERTINO_SUNGLASSES_ICON,
                        title: 'True Dark Mode',
                        trailing: CupertinoSwitch(
                          value: settingsBox.get(0).trueDark,
                          onChanged: (_) {
                            settingsBox.get(0).trueDark =
                                !settingsBox.get(0).trueDark;
                            settingsBox.get(0).save();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                ActionBlock(
                  blockEntries: [
                    BlockEntry(
                      leading: StylingHelper.CUPERTINO_AT_ICON,
                      title: 'About',
                      navigateTo: SettingsTabRoutingKeys.ABOUT.route,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    'by Kounex',
                    style: Theme.of(context).textTheme.caption,
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
