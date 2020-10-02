import 'package:flutter/material.dart';

import '../../../../../shared/general/base_card.dart';

class StatsContainer extends StatelessWidget {
  final String title;
  final List<Widget> children;

  StatsContainer({@required this.title, this.children});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      topPadding: 0.0,
      bottomPadding: 0.0,
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
