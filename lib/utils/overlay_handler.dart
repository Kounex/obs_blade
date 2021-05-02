import 'dart:async';

import 'package:flutter/material.dart';

import '../shared/animator/full_overlay.dart';

const Duration kShowDuration = Duration(milliseconds: 2000);
const Duration kAnimationDuration = Duration(milliseconds: 250);

/// Utility helper class to manage overlays - specifically app wide overlays, which
/// cover the full screen and make the app unusable while the overlay is active so
/// the focus lies on the overlay and the process which is running in the background
class OverlayHandler {
  static OverlayEntry? currentOverlayEntry;
  static Timer? currentOverlayTimer;
  static Timer? delayTimer;

  /// Any [content] can be displayed, just needs to be a [Widget]. [replaceIfActive], if true,
  /// will close any other overlay which may be active right now and display the new one then, otherwise
  /// the new overlay will be inserted on top
  static void showStatusOverlay(
      {required BuildContext context,
      required Widget content,
      Duration showDuration = kShowDuration,
      Duration delayDuration = const Duration(milliseconds: 250),
      bool replaceIfActive = false}) async {
    /// If a overlay is currently shown and [replaceIfActive] is false, we skip
    /// this function since we don't want to stack overlays and we didn't set
    /// [replaceIfActive]
    if (OverlayHandler.currentOverlayEntry == null || replaceIfActive) {
      if (replaceIfActive) {
        OverlayHandler.closeAnyOverlay();
      }

      /// I have set an [Timer] as a delay after which we actually show the overlay.
      /// This serves as a buffer so calls to [closeAnyOverlay] which may come right
      /// after in a MobX reaction for example have a chance to stop the overlay
      /// from being shown. If shown immediately without the delay the user might
      /// see an overlay for a very short period before being closed which might confuse
      /// the user and actually does not look to good - a user will not really see / feel
      /// this delay but this gives us enough time to react to this overlay wanting to be
      /// shown
      OverlayHandler.delayTimer = Timer(delayDuration, () {
        OverlayHandler.currentOverlayEntry = OverlayHandler.getStatusOverlay(
            content: content, showDuration: showDuration);
        Overlay.of(context, rootOverlay: true)!
            .insert(OverlayHandler.currentOverlayEntry!);
      });

      /// Calculating the maximum amount of time an overlay will be shown with all
      /// animations and the delay to remove it (if it hasn't already been removed
      /// manually from anywhere with the [closeAnyOverlay] function where all timers
      /// are canceled as well)
      OverlayHandler.currentOverlayTimer = Timer(
          Duration(
              milliseconds: delayDuration.inMilliseconds +
                  showDuration.inMilliseconds +
                  2 * kAnimationDuration.inMilliseconds),
          () => OverlayHandler.closeAnyOverlay());
    }
  }

  /// Manually close any overlay (if exists)
  static void closeAnyOverlay() {
    try {
      OverlayHandler.currentOverlayTimer?.cancel();
      OverlayHandler.delayTimer?.cancel();
      OverlayHandler.currentOverlayEntry?.remove();
      OverlayHandler.currentOverlayEntry = null;
    } catch (e) {
      throw Exception(
          'Could not handle "closeAnyOverlay" (utils/overlay_handler.dart) | $e');
    }
  }

  /// Function which actually returns the [OverlayEntry] used in
  /// [OverlayHelper.showStatusOverlay] and doesn't need to be called
  /// manually
  static OverlayEntry getStatusOverlay({
    required Widget content,
    required Duration showDuration,
  }) =>
      OverlayEntry(
        builder: (context) => FullOverlay(
          content: content,
          showDuration: showDuration,
          animationDuration: kAnimationDuration,
        ),
      );
}
