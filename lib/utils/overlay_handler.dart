import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

class OverlayHandler {
  static OverlayEntry currentOverlayEntry;
  static Timer currentOverlayTimer;

  static void showStatusOverlay(
      {BuildContext context,
      Widget content,
      Duration showDuration = const Duration(seconds: 2),
      bool replaceIfActive = false}) async {
    if (OverlayHandler.currentOverlayEntry == null || replaceIfActive) {
      if (replaceIfActive) {
        OverlayHandler.currentOverlayEntry?.remove();
        OverlayHandler.currentOverlayTimer?.cancel();
      }
      OverlayHandler.currentOverlayEntry =
          OverlayHandler.getStatusOverlay(context: context, content: content);
      Overlay.of(context).insert(
        OverlayHandler.currentOverlayEntry,
      );
      OverlayHandler.currentOverlayTimer = Timer(showDuration, () {
        OverlayHandler.currentOverlayEntry?.remove();
        OverlayHandler.currentOverlayEntry = null;
      });
    }
  }

  static OverlayEntry getStatusOverlay(
          {BuildContext context, Widget content}) =>
      OverlayEntry(
        builder: (context) => Positioned(
          top: (MediaQuery.of(context).size.height / 2) - 75.0,
          left: (MediaQuery.of(context).size.width / 2) - 75.0,
          child: Material(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9.0, sigmaY: 9.0),
              child: Container(
                height: 150.0,
                width: 150.0,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.all(
                    Radius.circular(12.0),
                  ),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
}
