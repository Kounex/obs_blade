import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:obs_blade/shared/general/base/base_card.dart';
import 'styling_helper.dart';

// A translucent color that is painted on top of the blurred backdrop as the
// dialog's background color
// Extracted from https://developer.apple.com/design/resources/.
const Color kDialogColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xCCF2F2F2),
  darkColor: Color(0xBF1E1E1E),
);

const double kDialogBlurAmount = 20.0;

class ModalHandler {
  static Future<T?> showBaseDialog<T>({
    required BuildContext context,
    required Widget dialogWidget,
    bool barrierDismissible = false,
  }) async =>
      showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => dialogWidget,
      );

  static Future<T?> showBaseBottomSheet<T>({
    required BuildContext context,
    required Widget modalWidget,
    bool useRootNavigator = true,
    bool barrierDismissible = false,
    double maxWidth = kBaseCardMaxWidth,
  }) async =>
      showModalBottomSheet(
        context: context,
        useRootNavigator: useRootNavigator,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => _bottomSheetWrapper(
          context: context,
          modalWidget: modalWidget,
          maxHeight: MediaQuery.of(context).size.height / 1.5,
          maxWidth: min(MediaQuery.of(context).size.width, maxWidth),
        ),
      );

  static Future<T?> showBaseCupertinoBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext, ScrollController) modalWidgetBuilder,
    bool useRootNavigator = true,
    double maxWidth = kBaseCardMaxWidth,
  }) async =>
      CupertinoScaffold.showCupertinoModalBottomSheet(
        expand: false,
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        shadow: BoxShadow(color: Colors.transparent),
        useRootNavigator: useRootNavigator,
        builder: (context) => _bottomSheetWrapper(
          context: context,
          modalWidget: modalWidgetBuilder(
            context,
            ModalScrollController.of(context)!,
          ),
          maxWidth: min(MediaQuery.of(context).size.width, maxWidth),
          blurryBackground: true,
        ),
      );

  static Widget _bottomSheetWrapper({
    required BuildContext context,
    required Widget modalWidget,
    double maxWidth = double.infinity,
    double maxHeight = double.infinity,
    bool blurryBackground = false,
  }) {
    Widget child = Container(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .cardColor
            .withOpacity(blurryBackground ? StylingHelper.opacity_blurry : 1),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(kBaseCardBorderRadius),
        ),
      ),
      child: modalWidget,
    );

    if (blurryBackground) {
      child = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: StylingHelper.sigma_blurry,
            sigmaY: StylingHelper.sigma_blurry,
          ),
          child: child,
        ),
      );
    }

    child = Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          maxWidth: maxWidth,
        ),
        child: child,
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: child,
        ),
      ),
    );
  }
}
