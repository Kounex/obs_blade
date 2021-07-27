import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum BaseResultIcon { Positive, Negative, Missing }

extension BaseResultIconFunctions on BaseResultIcon {
  IconData get data => const {
        BaseResultIcon.Positive: CupertinoIcons.check_mark_circled,
        BaseResultIcon.Negative: CupertinoIcons.clear_circled,
        BaseResultIcon.Missing: Icons.search_off,
      }[this]!;
}

class BaseResult extends StatelessWidget {
  final BaseResultIcon icon;
  final String? text;

  final double iconSize;

  BaseResult({
    this.icon = BaseResultIcon.Positive,
    this.text,
    this.iconSize = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          this.icon.data,
          size: this.iconSize,
        ),
        if (this.text != null)
          Padding(
            padding: EdgeInsets.only(top: 14.0),
            child: Text(
              this.text!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption,
            ),
          )
      ],
    );
  }
}
