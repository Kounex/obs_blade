import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Will hold some general styling stuff like "custom" icons or some
/// app wide layout constraints (if applicable)
class StylingHelper {
  /// Width threshold to trigger mobile or tablet view
  static const double max_width_mobile = 700.0;

  /// Main colors (primarly used for Themeing)
  static const Color primary_color = const Color(0xff101823);
  static const Color accent_color = const Color(0xffff4654);
  static const Color highlight_color = CupertinoColors.systemBlue;
  static const Color background_color = Colors.black;

  static const Color background_reduced_smearing_color =
      const Color.fromRGBO(5, 5, 5, 1.0);

  static const Color light_divider_color =
      const Color.fromRGBO(111, 111, 111, 0.6);

  static const double opacity_blurry = 0.75;

  /// Taken from [CupertinoNavigationBar]
  static const double sigma_blurry = 10.0;

  /// Bouncng scroll for all cases
  static ScrollPhysics get platformAwareScrollPhysics =>
      Platform.isIOS || Platform.isMacOS
          ? AlwaysScrollableScrollPhysics()
          : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  static Color surroundingAwareAccent(
      {BuildContext? context, Color? surroundingColor}) {
    assert(context != null || surroundingColor != null);
    return (surroundingColor ?? Theme.of(context!).cardColor)
                .computeLuminance() <
            0.2
        ? Colors.white
        : Colors.black;
  }
}
