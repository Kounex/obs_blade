import 'package:flutter/material.dart';

import '../../../../../types/extensions/list.dart';
import 'enumeration_entry.dart';

class EnumerationBlock extends StatelessWidget {
  final String? title;

  final bool ordered;
  final List<String>? entries;
  final List<EnumerationEntry>? customEntries;

  final double entrySpacing;

  EnumerationBlock({
    this.title,
    this.ordered = false,
    this.entries,
    this.customEntries,
    this.entrySpacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> usedEntries = List.from(
      (this.entries?.mapIndexed((text, index) => EnumerationEntry(
                  text: text, order: this.ordered ? index : null)) ??
              this.customEntries ??
              [])
          .expand((entry) => [
                entry,
                SizedBox(height: this.entrySpacing),
              ]),
    );

    if (usedEntries.isNotEmpty) usedEntries.removeLast();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (this.title != null) ...[
          Text(this.title!),
          SizedBox(height: 6.0),
        ],
        ...usedEntries,
        // if (usedEntries.isNotEmpty) SizedBox(height: 6.0),
      ],
    );
  }
}
