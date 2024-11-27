import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/enums/dashboard_element.dart';
import 'package:obs_blade/shared/general/base/card.dart';

class ElementBody extends StatelessWidget {
  final int index;
  final DashboardElement element;
  final Widget preview;

  const ElementBody({
    super.key,
    required this.index,
    required this.element,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      titleWidget: Row(
        children: [
          ReorderableDragStartListener(
            index: this.index,
            child: Icon(
              CupertinoIcons.circle_grid_3x3_fill,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              this.element.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      paddingChild: const EdgeInsets.all(0),
      topPadding: 0,
      bottomPadding: 18.0,
      child: BaseCard(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Align(
          child: this.preview,
        ),
      ),
    );
  }
}
