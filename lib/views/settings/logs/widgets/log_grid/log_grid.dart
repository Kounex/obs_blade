import 'dart:math';

import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base_card.dart';

import 'log_box.dart';

class LogGrid extends StatelessWidget {
  final List<int> datesMSWithLogs;

  LogGrid({required this.datesMSWithLogs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kBaseCardMaxWidth),
          child: LayoutBuilder(builder: (context, constraints) {
            double maxSize = 124.0;
            double spacing = 24.0;
            double constrainedWidth =
                min(kBaseCardMaxWidth, constraints.maxWidth);
            double outterSpace = MediaQuery.of(context).padding.left +
                MediaQuery.of(context).padding.right;
            double size = (constrainedWidth - (3 * spacing + outterSpace)) / 3;

            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: spacing,
              runSpacing: spacing,
              children: [
                ...this.datesMSWithLogs.map(
                      (dateMS) => LogBox(
                        dateMS: dateMS,
                        size: size > maxSize ? maxSize : size,
                      ),
                    ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
