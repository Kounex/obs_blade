import 'package:flutter/material.dart';

class EnumerationEntry extends StatelessWidget {
  final String? text;
  final Widget? customEntry;

  final double enumerationTopPadding;
  final double? enumerationSize;

  final int? order;
  final double levelSpacing;
  final int level;

  const EnumerationEntry({
    super.key,
    this.text,
    this.customEntry,
    this.enumerationTopPadding = 0,
    this.enumerationSize,
    this.order,
    this.levelSpacing = 12.0,
    this.level = 1,
  })  : assert(text != null || customEntry != null && level > 0),
        super();

  @override
  Widget build(BuildContext context) {
    double enumerationSize = this.enumerationSize ??
        Theme.of(context).textTheme.bodyLarge!.fontSize!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: this.enumerationTopPadding,
            left: this.levelSpacing * this.level,
            right: 12.0,
          ),
          child: this.order != null
              ? Text(
                  '${this.order.toString()}.',
                  style: TextStyle(fontSize: enumerationSize),
                )
              : Text(
                  '•',
                  style: TextStyle(fontSize: enumerationSize),
                ),
        ),
        Flexible(
          child: this.text != null
              ? Text(
                  this.text!,
                  style:
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                )
              : this.customEntry!,
        ),
      ],
    );
  }
}
