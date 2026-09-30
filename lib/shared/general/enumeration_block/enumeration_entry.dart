import 'package:flutter/material.dart';

import '../../design/app_typography.dart';

class EnumerationEntry extends StatelessWidget {
  final String? text;
  final Widget? customEntry;

  /// Replaces the bullet / order number (e.g. a colored dot) - centered on
  /// the entry's first line. Don't put a marker inside [customEntry] as
  /// well, or the entry shows two.
  final Widget? marker;

  final double enumerationTopPadding;
  final double? enumerationSize;

  final int? order;
  final double levelSpacing;
  final int level;

  const EnumerationEntry({
    super.key,
    this.text,
    this.customEntry,
    this.marker,
    this.enumerationTopPadding = 0,
    this.enumerationSize,
    this.order,
    this.levelSpacing = 12.0,
    this.level = 1,
  }) : assert(text != null || customEntry != null && level > 0),
       super();

  @override
  Widget build(BuildContext context) {
    /// One body style for marker, text and custom entries alike - every
    /// line of a list reads at the same size wherever it is used
    final TextStyle style = Theme.of(context).textTheme.bodyMedium!;

    final Widget marker = this.marker != null
        ? Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: this.marker!,
                ),
              ],
            ),
            style: style,
          )
        : Text(
            this.order != null
                ? '${this.order}.'
                : this.level > 1
                ? '◦'
                : '•',
            style: this.enumerationSize != null
                ? style.copyWith(fontSize: this.enumerationSize)
                : style,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: this.enumerationTopPadding,
            left: this.levelSpacing * this.level,
            right: 12.0,
          ),
          child: marker,
        ),
        Flexible(
          child: this.text != null
              ? Text(
                  this.text!,
                  style: style.copyWith(fontFeatures: kTabularFigures),
                )
              : DefaultTextStyle.merge(style: style, child: this.customEntry!),
        ),
      ],
    );
  }
}
