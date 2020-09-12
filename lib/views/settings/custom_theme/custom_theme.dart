import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../shared/general/base_card.dart';
import '../../../shared/general/transculent_cupertino_navbar_wrapper.dart';
import '../../../types/enums/hive_keys.dart';
import 'widgets/theme_active/theme_active.dart';
import 'widgets/theme_colors/theme_colors.dart';

class CustomThemeView extends StatefulWidget {
  @override
  _CustomThemeViewState createState() => _CustomThemeViewState();
}

class _CustomThemeViewState extends State<CustomThemeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TransculentCupertinoNavBarWrapper(
        previousTitle: 'Settings',
        title: 'Custom Theme',
        listViewChildren: [
          ValueListenableBuilder(
            valueListenable: Hive.box(HiveKeys.Settings.name).listenable(),
            builder: (context, Box settingsBox, child) => Column(
              children: [
                BaseCard(
                  bottomPadding: 12.0,
                  child: ThemeActive(settingsBox: settingsBox),
                ),
                BaseCard(
                  child: ThemeColors(settingsBox: settingsBox),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
