import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
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
    super.key,
    this.title,
    this.description,
    this.descriptionWidget,
    required this.blockEntries,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> entriesWithDivider = [];
    for (var i = 0; i < this.blockEntries.length; i++) {
      final BlockEntry entry = this.blockEntries[i];

      /// Rows animate in/out (e.g. Reduce Smearing only exists while True
      /// Dark is active) - the AnimatedSize stays mounted and tweens the
      /// height whenever [BlockEntry.visible] flips
      entriesWithDivider.add(
        ClipRect(
          child: AnimatedSize(
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            alignment: Alignment.topCenter,
            child: entry.visible
                ? entry
                : const SizedBox(width: double.infinity),
          ),
        ),
      );

      /// Inset divider between two visible entries (no trailing divider
      /// after the last visible one)
      final bool hasVisibleEntryAfter = this.blockEntries
          .skip(i + 1)
          .any((entry) => entry.visible);
      if (entry.visible && hasVisibleEntryAfter) {
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
    }

    return Padding(
      padding: EdgeInsets.only(top: !this.dense ? AppSpacing.xl : 0.0),
      child: BaseCard(
        above: this.title != null && this.title!.isNotEmpty
            ? Padding(
                padding: EdgeInsets.only(
                  left: this.generalizedPadding + 18,
                  right: this.generalizedPadding + 18,
                ),
                child: Text(
                  this.title!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              )
            : null,
        below: this.descriptionWidget != null || this.description != null
            ? Padding(
                padding: EdgeInsets.only(
                  left: this.generalizedPadding + 18,
                  right: this.generalizedPadding + 18,
                  bottom: 12.0,
                ),
                child:
                    this.descriptionWidget ??
                    Text(
                      this.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              )
            : null,
        topPadding: 8.0,
        bottomPadding: 12.0,
        paddingChild: const EdgeInsets.all(0),
        child: Container(
          color: Theme.of(context).cardColor,
          child: Column(children: entriesWithDivider),
        ),
      ),
    );
  }
}
