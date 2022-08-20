import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../models/custom_theme.dart';
import '../../../../shared/animator/fader.dart';
import '../../../../shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../types/extensions/string.dart';
import '../../../../utils/styling_helper.dart';
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
              CustomTheme? customTheme =
                  StylingHelper.currentCustomTheme(settingsBox);

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
