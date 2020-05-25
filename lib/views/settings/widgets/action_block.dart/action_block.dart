import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'block_entry.dart';
import 'light_divider.dart';

class ActionBlock extends StatelessWidget {
  final List<BlockEntry> blockEntries;
  final bool dense;

  ActionBlock({@required this.blockEntries, this.dense = false});

  @override
  Widget build(BuildContext context) {
    List<Widget> entriesWithDivider = [];
    this.blockEntries.forEach((entry) {
      entriesWithDivider.add(
        ListTile(
          dense: true,
          leading: Icon(
            entry.leading,
            size: 32.0,
          ),
          title: entry.title,
          trailing: entry.navigateTo != null
              ? Icon(CupertinoIcons.right_chevron)
              : entry.trailing,
          onTap: entry.navigateTo != null
              ? () {
                  Navigator.of(context).pushNamed(entry.navigateTo);
                }
              : null,
        ),
      );
      entriesWithDivider.add(
        Padding(
          padding: EdgeInsets.only(left: 70.0),
          child: LightDivider(),
        ),
      );
    });

    /// Remove last so we can use the full width divider
    /// as the last one
    entriesWithDivider.removeLast();

    return Padding(
      padding: EdgeInsets.only(top: !this.dense ? 24.0 : 0.0),
      child: Container(
        color: Theme.of(context).cardColor,
        child: Column(
          children: [
            LightDivider(),
            ...entriesWithDivider,
            LightDivider(),
          ],
        ),
      ),
    );
  }
}
