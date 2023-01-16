import 'package:flutter/material.dart';
import '../../../../shared/general/base/card.dart';

import '../../../../shared/general/base/divider.dart';
import 'block_entry.dart';

class ActionBlock extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? descriptionWidget;
  final List<BlockEntry> blockEntries;
  final bool dense;

  final double generalizedPadding = 14.0;
  final double iconSize = 32.0;

  const ActionBlock({
    Key? key,
    this.title,
    this.description,
    this.descriptionWidget,
    required this.blockEntries,
    this.dense = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> entriesWithDivider = [];
    for (var entry in this.blockEntries) {
      entriesWithDivider.add(entry);
      entriesWithDivider.add(
        Padding(
          padding: EdgeInsets.only(
            left: entry.leading != null
                ? 2 * this.generalizedPadding + this.iconSize
                : this.generalizedPadding,
          ),
          child: const BaseDivider(),
        ),
      );
    }

    /// Remove last so we can use the full width divider
    /// as the last one
    entriesWithDivider.removeLast();

    return Padding(
      padding: EdgeInsets.only(top: !this.dense ? 24.0 : 0.0),
      child: BaseCard(
        above: this.title != null && this.title!.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(left: this.generalizedPadding + 16),
                child: Text(
                  this.title!.toUpperCase(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : null,
        below: this.descriptionWidget != null ||
                (this.description != null && this.title!.isNotEmpty)
            ? Padding(
                padding: EdgeInsets.only(left: this.generalizedPadding + 16),
                child: this.descriptionWidget ??
                    Text(
                      this.description!.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              )
            : null,
        topPadding: 8.0,
        bottomPadding: 12.0,
        paddingChild: const EdgeInsets.all(0),
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(
            children: entriesWithDivider,
          ),
        ),
      ),
    );
  }
}
