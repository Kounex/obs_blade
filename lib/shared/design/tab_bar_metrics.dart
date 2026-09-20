import 'package:flutter/widgets.dart';

import 'app_spacing.dart';

/// Bottom clearance for content hosted inside the tab scaffold: the glass
/// tab bar's full occupied height plus a resting [gap] between content and
/// the bar's top edge.
///
/// Inside tab screens this is just `MediaQuery.paddingOf(context).bottom`
/// plus [gap]: TabBase's Scaffold (bottomNavigationBar + extendBody) first
/// consumes the bottom safe-area inset and then injects the bar's occupied
/// height (the stock Cupertino tab bar's 50pt + that inset) into the
/// body's `padding.bottom` (Scaffold's body builder takes
/// `max(padding.bottom, bottomWidgetsHeight)` when the body extends behind
/// the bar). The value therefore already includes both the bar and the
/// home-indicator inset - adding either again double-counts, which is
/// exactly what the legacy `2 * kBottomNavigationBarHeight + inset / 2`
/// formulas did.
///
/// Contexts outside the tab scaffold (root-navigator modals, dialogs)
/// degrade gracefully: their `padding.bottom` is the raw safe-area inset.
double tabBarBottomPadding(
  BuildContext context, {
  double gap = AppSpacing.md,
}) => MediaQuery.paddingOf(context).bottom + gap;
