import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';

/// The dashboard's uniform element chrome ("content = card"): 12px side
/// margins, no vertical margin - the layout composer
/// (`buildOrderedDashboardSlivers`) owns the vertical rhythm - around the
/// standard BaseCard fill / radius / hairline.
///
/// Used for the composer-owned content cards (scene items/audio, scene
/// preview, stats). Self-contained card widgets (ExposedControls,
/// ProfileSceneCollection, StatsContainer) apply the same 12px-grid values
/// on their own BaseCard arguments instead.
class DashboardElementCard extends StatelessWidget {
  final Widget child;
  final String? title;

  /// Outer margin - defaults to the 12px side grid. The tablet scene pair
  /// overrides per side to compose the 12px inter-card gutter.
  final EdgeInsetsGeometry margin;

  /// Inner padding around [child] - zero by default so band-style content
  /// (tab strips, expansion tiles) spans the card edge-to-edge and picks up
  /// the rounded corners from the card's clip.
  final EdgeInsetsGeometry paddingChild;

  const DashboardElementCard({
    super.key,
    required this.child,
    this.title,
    this.margin = const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.paddingChild = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: this.margin,
      child: BaseCard(
        title: this.title,
        topPadding: 0.0,
        rightPadding: 0.0,
        bottomPadding: 0.0,
        leftPadding: 0.0,
        paddingChild: this.paddingChild,
        child: this.child,
      ),
    );
  }
}
