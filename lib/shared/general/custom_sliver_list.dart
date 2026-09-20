import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

class CustomSliverList extends StatelessWidget {
  final List<Widget> children;

  final double? customTopPadding;
  final double? customBottomPadding;

  const CustomSliverList({
    super.key,
    required this.children,
    this.customTopPadding,
    this.customBottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(
        top: this.customTopPadding ?? 0.0,
        right: MediaQuery.paddingOf(context).right,

        /// Default rest position: clear of the glass tab bar (its occupied
        /// height is already inside padding.bottom inside the tab
        /// scaffold) with a consistent gap above it
        bottom: this.customBottomPadding ?? tabBarBottomPadding(context),
        left: MediaQuery.paddingOf(context).left,
      ),
      sliver: SliverList(delegate: SliverChildListDelegate(this.children)),
    );
  }
}
