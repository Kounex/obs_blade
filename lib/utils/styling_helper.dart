import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/types/extensions/color.dart';

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
  ///
  /// TODO: Check why currently only [BouncingScrollPhysics] seems
  /// to work properly for the [RefresherAppBar] to always scroll on
  /// both iOS and Android
  static ScrollPhysics get platformAwareScrollPhysics => Platform.isIOS
      // ? const AlwaysScrollableScrollPhysics()
      ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
      // : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
      : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  static bool colorIsDark({BuildContext? context, Color? color}) {
    assert(context != null || color != null);
    return (color ?? Theme.of(context!).cardColor).computeLuminance() < 0.5;
  }

  static Color lightenDarkenColor(Color color, [int percent = 5]) =>
      StylingHelper.colorIsDark(color: color)
          ? color.lighten(percent)
          : color.darken(percent);

  static Color surroundingAwareAccent(
      {BuildContext? context, Color? surroundingColor}) {
    assert(context != null || surroundingColor != null);
    return StylingHelper.colorIsDark(context: context, color: surroundingColor)
        ? Colors.white
        : Colors.black;
  }

  static String brightnessAwareOBSLogo(BuildContext context) =>
      'assets/images/${Theme.of(context).brightness == Brightness.dark ? 'base_logo.png' : 'base_logo_dark.png'}';

  static bool isApple(BuildContext context, {TargetPlatform? platform}) =>
      (platform ?? Theme.of(context).platform) == TargetPlatform.iOS ||
      (platform ?? Theme.of(context).platform) == TargetPlatform.macOS;

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
