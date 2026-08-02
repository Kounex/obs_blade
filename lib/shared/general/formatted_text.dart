import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

class FormattedText extends StatelessWidget {
  final String label;
  final String? text;
  final double width;
  final String? unit;

  const FormattedText({
    super.key,
    required this.label,
    this.text,
    this.width = 50.0,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    /// Mirrors the look of the previously used disabled [TextField]:
    /// floating label above a disabled-grey value with tabular figures.
    /// The value tweens between numeric changes (1s stats cadence) via
    /// [CountUpText] and snaps for non-numeric values.
    final TextStyle valueStyle =
        Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).disabledColor,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            );

    return SizedBox(
      width: this.width,
      child: InputDecorator(
        isEmpty: false,
        baseStyle: valueStyle,
        decoration: InputDecoration(
          isDense: true,
          enabled: false,
          labelText: this.label,
          labelStyle:
              Theme.of(context).textTheme.bodyMedium!.copyWith(height: 0.75),
        ),
        child: ClipRect(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CountUpText(
                  value: this.text ?? '-',
                  style: valueStyle,
                  maxLines: 1,
                ),
              ),
              if (this.text != null && this.unit != null)
                Text(
                  this.unit!,
                  style: valueStyle,
                  maxLines: 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
