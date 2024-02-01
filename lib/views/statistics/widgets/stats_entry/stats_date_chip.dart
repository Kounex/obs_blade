import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class StatsDateChip extends StatelessWidget {
  final String label;
  final String content;

  const StatsDateChip({
    Key? key,
    required this.label,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.0,
      child: Chip(
        labelPadding: const EdgeInsets.all(2.0),
        backgroundColor:
            StylingHelper.lightenDarkenColor(Theme.of(context).cardColor, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(64.0),
        ),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
        label: Row(
          children: [
            SizedBox(
              height: 32.0,
              child: Chip(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(64.0),
                ),
                side: BorderSide.none,
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                backgroundColor: Theme.of(context).cardColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: SizedBox(
                  width: 40.0,
                  child: Text(
                    this.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall!,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                this.content,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontFeatures: [
                    const FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
