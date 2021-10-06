import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import 'package:obs_blade/shared/general/hive_builder.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../shared/animator/fader.dart';
import '../../../../types/extensions/string.dart';
import 'scroll_refresh_icon.dart';

const double kRefresherAppBarHeight = 44.0;

class RefresherAppBar extends StatelessWidget {
  final double? expandedHeight;

  const RefresherAppBar({
    Key? key,
    this.expandedHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TransculentSliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      toolbarHeight: kRefresherAppBarHeight,
      expandedHeight: this.expandedHeight,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoDynamicColor.withBrightness(
                color: Color(0x4C000000),
                darkColor: Color(0x29FFFFFF),
              ),
              width: 0.0,
              style: BorderStyle.solid,
            ),
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          title: LayoutBuilder(
            builder: (context, constraints) {
              if ((constraints.maxHeight -
                          (MediaQuery.of(context).viewPadding.top - 16))
                      .toInt() <=
                  kRefresherAppBarHeight.toInt()) {
                return Fader(
                  child: Transform.translate(
                    offset: const Offset(0, 4.0),
                    child: Text(
                      'OBS Blade',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navTitleTextStyle,
                    ),
                  ),
                );
              }
              return ScrollRefreshIcon(
                expandedBarHeight: this.expandedHeight,
                currentBarHeight: constraints.maxHeight,
              );
            },
          ),
          background: HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            rebuildKeys: const [
              SettingsKeys.CustomTheme,
              SettingsKeys.ActiveCustomThemeUUID
            ],
            builder: (context, settingsBox, child) {
              CustomTheme? customTheme;

              if (settingsBox.get(SettingsKeys.CustomTheme.name,
                  defaultValue: false)) {
                try {
                  customTheme = Hive.box<CustomTheme>(HiveKeys.CustomTheme.name)
                      .values
                      .firstWhere(
                        (customTheme) =>
                            customTheme.uuid ==
                            settingsBox
                                .get(SettingsKeys.ActiveCustomThemeUUID.name),
                      );
                } catch (_) {}
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    color: customTheme?.logoAppBarColorHex?.hexToColor() ??
                        Colors.transparent,
                  ),
                  customTheme?.customLogo != null
                      ? Image.memory(base64Decode(customTheme!.customLogo!))
                      : Image.asset(
                          StylingHelper.brightnessAwareOBSLogo(context),
                        ),
                ],
              );
            },
          ),
          collapseMode: CollapseMode.parallax,
          stretchModes: const [
            StretchMode.blurBackground,
            StretchMode.zoomBackground
          ],
        ),
      ),
    );
  }
}
