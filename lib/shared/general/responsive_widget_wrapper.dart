import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class ResponsiveWidgetWrapper extends StatelessWidget {
  final Widget mobileWidget;
  final Widget tabletWidget;

  ResponsiveWidgetWrapper(
      {@required this.mobileWidget, @required this.tabletWidget});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box(HiveKeys.Settings.name)
          .listenable(keys: [SettingsKeys.EnforceTabletMode.name]),
      builder: (context, Box settingsBox, child) => Padding(
        padding: const EdgeInsets.only(top: 42.0),
        child: MediaQuery.of(context).size.width >
                    StylingHelper.MAX_WIDTH_MOBILE ||
                settingsBox.get(SettingsKeys.EnforceTabletMode.name,
                    defaultValue: false)
            ? this.tabletWidget
            : this.mobileWidget,
      ),
    );
  }
}
