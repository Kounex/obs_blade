import 'dart:async';

import 'package:flutter/material.dart';

import '../shared/animator/full_overlay.dart';

const Duration kShowDuration = Duration(milliseconds: 2000);
const Duration kAnimationDuration = Duration(milliseconds: 250);

/// Utility helper class to manage overlays - specifically app wide overlays, which
/// cover the full screen and make the app unusable while the overlay is active so
/// the focus lies on the overlay and the process which is running in the background
class OverlayHandler {
  static OverlayEntry currentOverlayEntry;
  static Timer currentOverlayTimer;

  /// Any [content] can be displayed, just needs to be a [Widget]. [replaceIfActive], if true,
  /// will close any other overlay which may be active right now and display the new one then, otherwise
  /// the new overlay will be inserted on top
  static void showStatusOverlay(
      {BuildContext context,
      Widget content,
      Duration showDuration = kShowDuration,
      bool replaceIfActive = false}) async {
    if (OverlayHandler.currentOverlayEntry == null || replaceIfActive) {
      if (replaceIfActive) {
        OverlayHandler.closeAnyOverlay();
      }
      OverlayHandler.currentOverlayEntry = OverlayHandler.getStatusOverlay(
          context: context, content: content, showDuration: showDuration);
      Overlay.of(context, rootOverlay: true).insert(
        OverlayHandler.currentOverlayEntry,
      );
      OverlayHandler.currentOverlayTimer = Timer(
          Duration(
              milliseconds: showDuration.inMilliseconds +
                  2 * kAnimationDuration.inMilliseconds), () {
        OverlayHandler.currentOverlayEntry?.remove();
        OverlayHandler.currentOverlayEntry = null;
      });
    }
  }

  /// Manually close any overlay (if exists)
  static void closeAnyOverlay() {
    OverlayHandler.currentOverlayTimer?.cancel();
    OverlayHandler.currentOverlayEntry?.remove();
    OverlayHandler.currentOverlayEntry = null;
  }

  /// Function which actually returns the [OverlayEntry] used in
  /// [OverlayHelper.showStatusOverlay] and doesn't need to be called
  /// manually
  static OverlayEntry getStatusOverlay(
          {BuildContext context, Widget content, Duration showDuration}) =>
      OverlayEntry(
        builder: (context) => FullOverlay(
          content: content,
          showDuration: showDuration,
          animationDuration: kAnimationDuration,
        ),
      );
}
