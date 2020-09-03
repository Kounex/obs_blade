import 'package:flutter/material.dart';

class CustomSliverList extends StatelessWidget {
  final List<Widget> children;

  final double customTopPadding;
  final double customBottomPadding;

  CustomSliverList(
      {@required this.children,
      this.customTopPadding,
      this.customBottomPadding});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.only(
        top: this.customTopPadding ?? 0.0,
        right: MediaQuery.of(context).padding.right,
        bottom: this.customBottomPadding ?? kBottomNavigationBarHeight,
        left: MediaQuery.of(context).padding.left,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate(this.children),
      ),
    );
  }
}
