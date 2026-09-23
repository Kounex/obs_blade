import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import '../shared/animator/fader.dart';
import '../shared/design/design.dart';
import '../shared/general/base/card.dart';
import '../shared/general/base/icon_button.dart';
import 'styling_helper.dart';

class ModalHandler {
  static Duration transitionDelayDuration = const Duration(milliseconds: 350);

  static Future<T?> showFullscreen<T>({
    required BuildContext context,
    required Widget content,
    void Function()? onClose,
  }) async => showDialog(
    useSafeArea: false,
    context: context,
    builder: (context) => Fader(
      child: Material(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            content,
            Positioned(
              top: 12.0 + MediaQuery.paddingOf(context).top,
              right: 12.0 + MediaQuery.paddingOf(context).right,
              child: BaseIconButton(
                backgroundColor: Colors.transparent,
                onTap: () {
                  onClose?.call();
                  Navigator.of(context).pop();
                },
                icon: CupertinoIcons.clear,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  static Future<T?> showBaseDialog<T>({
    required BuildContext context,
    required Widget dialogWidget,
    bool barrierDismissible = false,
  }) async => showAdaptiveDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => dialogWidget,
  );

  static Future<T?> showBaseBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext context) builder,
    bool useRootNavigator = true,
    bool barrierDismissible = false,
    bool enableDrag = false,
    bool includeCloseButton = false,
    double maxWidth = kBaseCardMaxWidth,

    /// Fraction of the screen height the sheet may occupy. `1.0` = no
    /// practical cap (SafeArea still applies). Chat sheets that need a
    /// top gap for barrier taps pass ~0.72.
    double maxHeightFraction = 1.0,
    double additionalBottomViewInsets = 0,

    /// Linear while a scroll-driven drag is tracking the finger. The
    /// default decelerate curve makes the open sheet barely move until
    /// the controller has travelled a long way. Drag-to-dismiss sheets
    /// use a linear curve unless the caller passed one.
    AnimationStyle? sheetAnimationStyle,
  }) async => showModalBottomSheet(
    context: context,
    useRootNavigator: useRootNavigator,
    isDismissible: barrierDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    sheetAnimationStyle: enableDrag
        ? (sheetAnimationStyle ??
              const AnimationStyle(
                curve: Curves.linear,
                reverseCurve: Curves.linear,
              ))
        : sheetAnimationStyle,
    builder: (context) => _bottomSheetWrapper(
      context: context,
      additionalBottomViewInsets: additionalBottomViewInsets,
      includeCloseButton: includeCloseButton,
      modalWidget: _ModalSheetBody(
        overscrollDismiss: enableDrag,
        child: builder(context),
      ),
      maxHeight: MediaQuery.sizeOf(context).height * maxHeightFraction,
      maxWidth: min(MediaQuery.sizeOf(context).width, maxWidth),
    ),
  );

  static Future<T?> showBaseCupertinoBottomSheet<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, ScrollController controller)
    modalWidgetBuilder,
    bool useRootNavigator = true,
    double maxWidth = double.infinity,
    bool? blurryBackground,
    bool includeCloseButton = true,
    double additionalBottomViewInsets = 0,
  }) async => CupertinoScaffold.showCupertinoModalBottomSheet(
    expand: false,
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    shadow: const BoxShadow(
      color: Colors.transparent,
      blurRadius: 0,
      offset: Offset(0, 0),
    ),
    useRootNavigator: useRootNavigator,
    builder: (context) => _bottomSheetWrapper(
      context: context,
      additionalBottomViewInsets: additionalBottomViewInsets,
      blurryBackground: blurryBackground ?? StylingHelper.isApple(context),
      includeCloseButton: includeCloseButton,
      modalWidget: modalWidgetBuilder(
        context,
        ModalScrollController.of(context)!,
      ),
      maxWidth: min(MediaQuery.sizeOf(context).width, maxWidth),
    ),
  );

  static Widget _bottomSheetWrapper({
    required BuildContext context,
    required Widget modalWidget,
    double maxWidth = double.infinity,
    double maxHeight = double.infinity,
    bool blurryBackground = false,
    bool includeCloseButton = false,
    double additionalBottomViewInsets = 0,
  }) {
    final AppGlass? glass = Theme.of(context).extension<AppGlass>();

    Widget child = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(
          alpha: blurryBackground ? AppGlass.barAlpha : 1.0,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(kBaseCardBorderRadius),
        ),
      ),
      child: Stack(
        children: [
          if (includeCloseButton)
            Positioned(
              top: 4.0,
              right: 4.0,
              child: Container(
                padding: const EdgeInsets.only(right: 4.0),
                alignment: Alignment.centerRight,
                child: BaseIconButton(
                  backgroundColor: Colors.transparent,
                  icon: CupertinoIcons.clear_circled_solid,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: includeCloseButton ? 24.0 : 0),
            child: modalWidget,
          ),
        ],
      ),
    );

    if (blurryBackground) {
      child = ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass?.sigma ?? StylingHelper.sigma_blurry,
            sigmaY: glass?.sigma ?? StylingHelper.sigma_blurry,
          ),
          child: child,
        ),
      );
    }

    // Shrink-wrap to the sheet height. A full-route child makes Flutter's
    // BottomSheet Material fill the screen and steal barrier taps even when
    // transparent. heightFactor keeps width centering via Align.
    // Bottom safe inset is applied by [_ModalSheetBody].
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            (MediaQuery.viewInsetsOf(context).bottom > 0
                ? additionalBottomViewInsets
                : 0),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// Height-capped sheet body. A scrolling descendant gets a real max height
/// (the modal column otherwise passes unbounded height, so a scroll view
/// grows with its child and overflows). When [overscrollDismiss] is set,
/// pulling past the top of that scroll view drags the sheet.
class _ModalSheetBody extends StatefulWidget {
  final Widget child;
  final bool overscrollDismiss;

  const _ModalSheetBody({required this.child, required this.overscrollDismiss});

  @override
  State<_ModalSheetBody> createState() => _ModalSheetBodyState();
}

class _ModalSheetBodyState extends State<_ModalSheetBody> {
  final GlobalKey _sheetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget body = this.widget.child;
    if (this.widget.overscrollDismiss) {
      body = ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
        ),
        child: _SheetOverscroll(sheetKey: this._sheetKey, child: body),
      );
    }
    return Column(
      key: this._sheetKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: body),
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );
  }
}

/// Pulling past the top of a scrolling sheet moves the sheet 1:1 with the
/// finger. Releasing springs it shut or back open.
///
/// Same decision iOS interactive dismiss uses: a downward flick closes even
/// when the drag was short, and a slower drag closes once it has passed
/// half the sheet — unless that release is flicking back upward. Otherwise
/// a critically damped spring (SwiftUI `spring(bounce: 0)`) returns it.
class _SheetOverscroll extends StatefulWidget {
  final Widget child;
  final GlobalKey sheetKey;

  const _SheetOverscroll({required this.child, required this.sheetKey});

  @override
  State<_SheetOverscroll> createState() => _SheetOverscrollState();
}

class _SheetOverscrollState extends State<_SheetOverscroll> {
  /// Points per second, matching Flutter's own `BottomSheet` drag-to-
  /// dismiss threshold (`_kMinFlingVelocity` in the framework's
  /// bottom_sheet.dart). 300, 150 and 100 were all tuned against
  /// `ScrollEndNotification.dragDetails.primaryVelocity`, which is the
  /// scroll view's *physics-filtered* velocity - a real flick that started
  /// inside scrollable content read as a much smaller number through that
  /// pipeline than the same flick starting outside it (where the
  /// framework's own drag handling, reading raw pointer velocity, made the
  /// fling threshold easy to hit). Tracking raw pointer velocity ourselves
  /// (below) and comparing against the framework's own number fixes that
  /// mismatch instead of keeps chasing the wrong signal.
  static const double _flickVelocity = 700.0;

  static const double _distanceThreshold = 0.5;

  /// Critically damped, so the release settles once and does not bounce.
  static final SpringDescription _spring =
      SpringDescription.withDurationAndBounce(
        duration: const Duration(milliseconds: 350),
        bounce: 0.0,
      );

  bool _pulled = false;
  bool _settled = true;

  /// Raw pointer velocity for the current touch - reset on every pointer
  /// down, fed on every move, read at release. Deliberately not sourced
  /// from `ScrollEndNotification` (see `_flickVelocity` above).
  VelocityTracker? _velocityTracker;

  void _onPointerDown(PointerDownEvent event) {
    this._velocityTracker = VelocityTracker.withKind(event.kind);
    this._velocityTracker!.addPosition(event.timeStamp, event.position);
  }

  double _trackedVelocity() =>
      this._velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0.0;

  /// The route controller is what the sheet's offset tracks. [ModalRoute.animation]
  /// is the curved proxy, which stays near 1.0 until the controller has
  /// moved a long way, so a finger drag has to drive the controller itself.
  AnimationController? _sheetController(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return null;
    // ignore: invalid_use_of_protected_member
    return route.controller;
  }

  double _sheetHeight(ScrollMetrics metrics) {
    final box =
        this.widget.sheetKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.height > 0) {
      return box.size.height;
    }
    return metrics.viewportDimension;
  }

  void _track(BuildContext context, OverscrollNotification notification) {
    final controller = this._sheetController(context);
    if (controller == null) return;
    final height = this._sheetHeight(notification.metrics);
    if (height <= 0) return;

    /// Raw finger delta. The scroll view's own overscroll is friction-damped,
    /// which made the sheet lag the finger.
    final fingerDown = notification.dragDetails?.primaryDelta;
    final pixels = (fingerDown != null && fingerDown > 0)
        ? fingerDown
        : -notification.overscroll;
    if (pixels <= 0) return;

    this._pulled = true;
    this._settled = false;
    controller.stop();
    controller.value = (controller.value - pixels / height).clamp(0.0, 1.0);
  }

  /// A reversed drag (finger moving back toward the boundary) doesn't
  /// generate more negative-[OverscrollNotification]s. What it produces
  /// instead depends on whether the sheet's content actually has scrollable
  /// range:
  /// - content taller than the sheet: the scroll view treats the reversal
  ///   as a normal, valid scroll away from the boundary (pixels moving off
  ///   0) and reports a plain [ScrollUpdateNotification].
  /// - content that fits without scrolling at all (min == max extent, e.g.
  ///   a short setup form): *every* direction is out of range, so the
  ///   reversal still reports as [OverscrollNotification] - just with a
  ///   positive `overscroll` instead of negative.
  /// Either way, redirect that motion into growing the sheet back. The
  /// list may itself scroll a few pixels away from the boundary as part of
  /// this in the scrollable-content case (nothing forces its position back)
  /// - an earlier version called `position.jumpTo()` to suppress that, but
  /// jumping a ScrollPosition while its own drag activity is still driving
  /// it replaces that activity, which silently ended the gesture: the
  /// sheet would snap instead of following the finger, and the same touch
  /// stopped producing any further notifications at all until lifted and
  /// restarted. A little list drift reads far better than a broken drag.
  void _trackRecovery(BuildContext context, ScrollNotification notification) {
    if (!this._pulled) return;
    final controller = this._sheetController(context);
    if (controller == null) return;
    final height = this._sheetHeight(notification.metrics);
    if (height <= 0) return;

    final dragDetails = switch (notification) {
      OverscrollNotification n => n.dragDetails,
      ScrollUpdateNotification n => n.dragDetails,
      _ => null,
    };
    final delta = dragDetails?.primaryDelta;
    if (delta == null || delta >= 0) return;

    controller.stop();
    controller.value = (controller.value - delta / height).clamp(0.0, 1.0);
  }

  void _settle(BuildContext context, double velocity) {
    if (this._settled || !this._pulled) return;
    final controller = this._sheetController(context);
    if (controller == null || controller.value >= 1.0) {
      this._settled = true;
      this._pulled = false;
      return;
    }
    this._settled = true;
    this._pulled = false;

    final height = () {
      final box =
          this.widget.sheetKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize && box.size.height > 0) {
        return box.size.height;
      }
      return 1.0;
    }();
    final travelled = 1.0 - controller.value;

    /// Fast downward flick closes on its own. A slower drag closes only
    /// after half the sheet, and not if the finger flicks back up.
    final dismiss =
        velocity > _flickVelocity ||
        (travelled > _distanceThreshold && velocity > -_flickVelocity);
    final target = dismiss ? 0.0 : 1.0;

    /// Spring velocity is in animation units per second (1 = one sheet
    /// height). Downward finger velocity continues the dismiss direction.
    final animationVelocity = -velocity / height;
    final simulation = SpringSimulation(
      _spring,
      controller.value,
      target,
      animationVelocity,
    );
    final done = controller.animateWith(simulation);
    if (dismiss) {
      done.whenComplete(() {
        if (!context.mounted) return;
        if (controller.value <= 0.01) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) return false;
        final atTop =
            notification.metrics.pixels <= notification.metrics.minScrollExtent;
        if (notification is OverscrollNotification &&
            notification.overscroll < 0 &&
            atTop) {
          this._track(context, notification);
          return false;
        }

        /// While already pulled, either a normal update (content with
        /// scrollable range recovering off the boundary) or a positive
        /// overscroll (content with no scrollable range at all, so a
        /// reversal is still "out of range") means the finger is moving
        /// back - grow the sheet instead of the content scrolling.
        if (this._pulled &&
            (notification is ScrollUpdateNotification ||
                (notification is OverscrollNotification &&
                    notification.overscroll > 0))) {
          this._trackRecovery(context, notification);
          return false;
        }
        if (notification is ScrollEndNotification) {
          this._settle(context, this._trackedVelocity());
        }
        return false;
      },
      child: Listener(
        onPointerDown: this._onPointerDown,
        onPointerMove: (event) =>
            this._velocityTracker?.addPosition(event.timeStamp, event.position),
        onPointerUp: (_) => this._settle(context, this._trackedVelocity()),
        onPointerCancel: (_) => this._settle(context, 0.0),
        child: this.widget.child,
      ),
    );
  }
}
