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

  /// Added CupertinoIcons
  static const IconData CUPERTINO_MACBOOK_ICON = const IconData(0xf390,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_QUESTION_ICON = const IconData(0xf445,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_AT_ICON = const IconData(0xf3d9,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  static const IconData CUPERTINO_SUNGLASSES_ICON = const IconData(0xf43f,
      fontFamily: CupertinoIcons.iconFont,
      fontPackage: CupertinoIcons.iconFontPackage);

  /// TODO: Wrapping [] with [] for other Platforms then Apple, scrolling works as intended
  /// (behaviour like Apple stuff) - need to confirm if this also applies to Apple, so I can
  /// use this approach for any Platform instead of making a distinction here
  static ScrollPhysics get platformAwareScrollPhysics =>
      Platform.isIOS || Platform.isMacOS
          ? AlwaysScrollableScrollPhysics()
          : BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
