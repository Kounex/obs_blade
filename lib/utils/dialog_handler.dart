import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// A translucent color that is painted on top of the blurred backdrop as the
// dialog's background color
// Extracted from https://developer.apple.com/design/resources/.
const Color kDialogColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xCCF2F2F2),
  darkColor: Color(0xBF1E1E1E),
);

const double kDialogBlurAmount = 20.0;

class DialogHandler {
  static Future<T> showBaseDialog<T>(
          {@required BuildContext context,
          @required Widget dialogWidget,
          bool barrierDismissible = false}) async =>
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => dialogWidget,
      );
}
