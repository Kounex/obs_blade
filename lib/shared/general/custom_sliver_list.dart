import 'package:flutter/material.dart';

class CustomSliverList extends StatelessWidget {
  final List<Widget> children;

  final double? customTopPadding;
  final double? customBottomPadding;

  const CustomSliverList({
    Key? key,
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
        bottom: this.customBottomPadding ??
            (2 * kBottomNavigationBarHeight +
                MediaQuery.paddingOf(context).bottom / 2),
        left: MediaQuery.paddingOf(context).left,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate(this.children),
      ),
    );
  }
}
