import 'dart:async';

import 'package:flutter/material.dart';
import 'package:obs_station/shared/animator/full_overlay.dart';

const Duration kShowDuration = Duration(milliseconds: 2000);
const Duration kAnimationDuration = Duration(milliseconds: 250);

class OverlayHandler {
  static OverlayEntry currentOverlayEntry;
  static Timer currentOverlayTimer;

  static void showStatusOverlay(
      {BuildContext context,
      Widget content,
      Duration showDuration = kShowDuration,
      bool replaceIfActive = false}) async {
    if (OverlayHandler.currentOverlayEntry == null || replaceIfActive) {
      if (replaceIfActive) {
        OverlayHandler.currentOverlayEntry?.remove();
        OverlayHandler.currentOverlayTimer?.cancel();
      }
      OverlayHandler.currentOverlayEntry = OverlayHandler.getStatusOverlay(
          context: context, content: content, showDuration: showDuration);
      Overlay.of(context).insert(
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

  static OverlayEntry getStatusOverlay(
          {BuildContext context, Widget content, Duration showDuration}) =>
      OverlayEntry(
          builder: (context) => FullOverlay(
                content: content,
                showDuration: showDuration,
                animationDuration: kAnimationDuration,
              ));
}
