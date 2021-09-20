import 'package:flutter/material.dart';

import '../../types/enums/hive_keys.dart';
import '../../types/enums/settings_keys.dart';
import '../../utils/styling_helper.dart';
import 'hive_builder.dart';

class ResponsiveWidgetWrapper extends StatelessWidget {
  final Widget mobileWidget;
  final Widget tabletWidget;

  const ResponsiveWidgetWrapper({
    Key? key,
    required this.mobileWidget,
    required this.tabletWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HiveBuilder<dynamic>(
      hiveKey: HiveKeys.Settings,
      rebuildKeys: const [SettingsKeys.EnforceTabletMode],
      builder: (context, settingsBox, child) =>
          MediaQuery.of(context).size.width > StylingHelper.max_width_mobile ||
                  settingsBox.get(SettingsKeys.EnforceTabletMode.name,
                      defaultValue: false)
              ? this.tabletWidget
              : this.mobileWidget,
    );
  }
}
