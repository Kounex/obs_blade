import 'package:flutter/material.dart';

import '../../../../../shared/general/base/base_card.dart';

class StatsContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final double? elevation;

  StatsContainer({
    required this.title,
    required this.children,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      topPadding: 0.0,
      bottomPadding: 0.0,
      elevation: this.elevation,
      titleWidget:
          Text(this.title, style: Theme.of(context).textTheme.headline6),
      child: Wrap(
        spacing: 24.0,
        runSpacing: 24.0,
        children: this.children,
      ),
      centerChild: false,
    );
  }
}
