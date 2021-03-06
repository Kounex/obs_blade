import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'block_entry.dart';
import 'light_divider.dart';

class ActionBlock extends StatelessWidget {
  final String? title;
  final List<BlockEntry> blockEntries;
  final bool dense;

  final double generalizedPadding = 14.0;
  final double iconSize = 32.0;
  final double entryHeight = 42.0;

  ActionBlock({this.title, required this.blockEntries, this.dense = false});

  @override
  Widget build(BuildContext context) {
    List<Widget> entriesWithDivider = [];
    this.blockEntries.forEach((entry) {
      entriesWithDivider.add(entry);
      entriesWithDivider.add(
        Padding(
          padding: EdgeInsets.only(
              left: entry.leading != null
                  ? 2 * this.generalizedPadding + this.iconSize
                  : this.generalizedPadding),
          child: LightDivider(),
        ),
      );
    });

    /// Remove last so we can use the full width divider
    /// as the last one
    entriesWithDivider.removeLast();

    return Padding(
      padding: EdgeInsets.only(top: !this.dense ? 24.0 : 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (this.title != null && this.title!.length > 0)
            Padding(
              padding:
                  EdgeInsets.only(left: this.generalizedPadding, bottom: 7.0),
              child: Text(
                this.title!.toUpperCase(),
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          Container(
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                LightDivider(),
                ...entriesWithDivider,
                LightDivider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
