import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/custom_theme.dart';
import '../types/enums/hive_keys.dart';
import '../types/enums/settings_keys.dart';

/// Will hold some general styling stuff like "custom" icons or some
/// app wide layout constraints (if applicable)
class StylingHelper {
  /// Width threshold to trigger mobile or tablet view
  static const double max_width_mobile = 700.0;

  /// Main colors (primarly used for Themeing)
  static const Color primary_color = Color(0xff101823);
  static const Color accent_color = Color(0xffff4654);
  static const Color highlight_color = CupertinoColors.systemBlue;
  static const Color background_color = Colors.black;

  static const Color background_reduced_smearing_color =
      Color.fromRGBO(5, 5, 5, 1.0);

  static const Color light_divider_color = Color.fromRGBO(111, 111, 111, 1.0);

  static const double opacity_blurry = 0.75;

  /// Taken from [CupertinoNavigationBar]
  static const double sigma_blurry = 10.0;

  /// Bouncing scroll for all cases
  static ScrollPhysics get platformAwareScrollPhysics => Platform.isIOS
      ? const AlwaysScrollableScrollPhysics()
      : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  static Color surroundingAwareAccent(
      {BuildContext? context, Color? surroundingColor}) {
    assert(context != null || surroundingColor != null);
    return (surroundingColor ?? Theme.of(context!).cardColor)
                .computeLuminance() <
            0.3
        ? Colors.white
        : Colors.black;
  }

  static String brightnessAwareOBSLogo(BuildContext context) =>
      'assets/images/${Theme.of(context).brightness == Brightness.dark ? 'base_logo.png' : 'base_logo_dark.png'}';

  static CustomTheme? currentCustomTheme([Box<dynamic>? settingsBox]) {
    settingsBox = settingsBox ?? Hive.box(HiveKeys.Settings.name);

    CustomTheme? customTheme;

    if (settingsBox.get(SettingsKeys.CustomTheme.name, defaultValue: false)) {
      try {
        customTheme =
            Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).values.firstWhere(
                  (customTheme) =>
                      customTheme.uuid ==
                      settingsBox!.get(SettingsKeys.ActiveCustomThemeUUID.name),
                );
      } catch (_) {}
    }

    return customTheme;
  }
}
