import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../design/animated_result_icon.dart';

enum BaseResultIcon { Positive, Negative, Missing }

extension BaseResultIconFunctions on BaseResultIcon {
  /// Static fallback glyphs - kept in sync with the stroke-drawn
  /// [AnimatedResultIcon] painter (check / cross / question mark)
  IconData get data => const {
        BaseResultIcon.Positive: CupertinoIcons.check_mark_circled,
        BaseResultIcon.Negative: CupertinoIcons.clear_circled,
        BaseResultIcon.Missing: CupertinoIcons.question_circle,
      }[this]!;

  AnimatedResultType get animatedType => const {
        BaseResultIcon.Positive: AnimatedResultType.positive,
        BaseResultIcon.Negative: AnimatedResultType.negative,
        BaseResultIcon.Missing: AnimatedResultType.missing,
      }[this]!;
}

class BaseResult extends StatelessWidget {
  final BaseResultIcon icon;

  final String? text;

  final double iconSize;
  final Color? iconColor;

  const BaseResult({
    super.key,
    this.icon = BaseResultIcon.Positive,
    this.text,
    this.iconSize = 32.0,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedResultIcon(
          type: this.icon.animatedType,
          size: this.iconSize,
          color: this.iconColor,
        ),
        if (this.text != null)
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: Text(
              this.text!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
      ],
    );
  }
}
