import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/basic/question_mark_tooltip.dart';
import '../../../../utils/styling_helper.dart';
import 'block_entry.dart';
import 'light_divider.dart';

class ActionBlock extends StatelessWidget {
  final String title;
  final List<BlockEntry> blockEntries;
  final bool dense;

  final double generalizedPadding = 14.0;
  final double iconSize = 32.0;
  final double entryHeight = 42.0;

  ActionBlock({this.title, @required this.blockEntries, this.dense = false});

  @override
  Widget build(BuildContext context) {
    List<Widget> entriesWithDivider = [];
    this.blockEntries.forEach((entry) {
      entriesWithDivider.add(
        GestureDetector(
          onTap: entry.navigateTo != null
              ? () {
                  Navigator.of(context).pushNamed(entry.navigateTo);
                }
              : null,
          child: Container(
            color: StylingHelper.MAIN_BLUE,
            height: this.entryHeight,
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: EdgeInsets.only(
                  left: this.generalizedPadding,
                  right: this.generalizedPadding),
              child: Row(
                children: [
                  if (entry.leading != null)
                    Padding(
                      padding: EdgeInsets.only(right: this.generalizedPadding),
                      child: Icon(
                        entry.leading,
                        size: this.iconSize,
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(entry.title,
                            style: Theme.of(context).textTheme.subtitle1
                            // .copyWith(fontSize: 15.0),
                            ),
                        if (entry.help != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: QuestionMarkTooltip(message: entry.help),
                          )
                      ],
                    ),
                  ),
                  entry.navigateTo != null
                      ? Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        )
                      : entry.trailing,
                ],
              ),
            ),
          ),
        ),
      );
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
          if (this.title != null && this.title.length > 0)
            Padding(
              padding:
                  EdgeInsets.only(left: this.generalizedPadding, bottom: 7.0),
              child: Text(
                this.title.toUpperCase(),
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
