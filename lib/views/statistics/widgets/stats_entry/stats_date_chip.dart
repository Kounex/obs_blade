import 'dart:ui';

import 'package:flutter/material.dart';

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
    return Chip(
      labelPadding: const EdgeInsets.all(2.0),
      // shape: LinearBorder.none,
      label: Row(
        children: [
          Chip(
            padding: const EdgeInsets.all(0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.black26,
            label: SizedBox(
              width: 40.0,
              child: Text(
                this.label,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              this.content,
              style: const TextStyle(
                fontFeatures: [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
