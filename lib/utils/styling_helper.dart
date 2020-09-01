import 'dart:io';

import 'package:flutter/cupertino.dart';

/// Will hold some general styling stuff like "custom" icons or some
/// app wide layout constraints (if applicable)
class StylingHelper {
  /// Width threshold to trigger mobile or tablet view
  static const double MAX_WIDTH_MOBILE = 700.0;

  /// Main colors (primarly used for Themeing)
  static const Color MAIN_BLUE = const Color(0xff101823);
  static const Color MAIN_RED = const Color(0xffff4654);

  static const double OPACITY_BLURRY = 0.75;

  /// Taken from [CupertinoNavigationBar]
  static const double SIGMA_BLURRY = 10.0;

  static const Color BLACK_REDUCED_SMEARING =
      const Color.fromRGBO(5, 5, 5, 1.0);

  static const Color LIGHT_DIVIDER_COLOR =
      const Color.fromRGBO(111, 111, 111, 1.0);

  /// Added CupertinoIcons
  static const IconData CUPERTINO_MACBOOK_ICON = const IconData(0xf466,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_QUESTION_ICON = const IconData(0xf445,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_QUESTION_ICON_CLEAN = const IconData(0xf444,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_AT_ICON = const IconData(0xf3d9,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_SUNGLASSES_ICON = const IconData(0xf43f,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_THEME_ICON = const IconData(0xf40e,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_REDUCE_SMEARING_ICON = const IconData(0xf3ce,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_LOCK_OPEN_ICON = const IconData(0xf3b5,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_LOCK_CLOSED_ICON = const IconData(0xf392,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_INFO_ICON = const IconData(0xf44D,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_BAR_ICON = const IconData(0xf2b5,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_RECTS_OVERLAP = const IconData(0xf3ef,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_RECTS_OVERLAP_SOLID = const IconData(0xf3f0,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_LANDSCAPE_IMAGE = const IconData(0xf2e4,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  /// Bouncng scroll for all cases
  static ScrollPhysics get platformAwareScrollPhysics =>
      Platform.isIOS || Platform.isMacOS
          ? AlwaysScrollableScrollPhysics()
          : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
