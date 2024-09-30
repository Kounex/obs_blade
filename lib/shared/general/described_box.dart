import 'package:flutter/material.dart';

class DescribedBox extends StatelessWidget {
  final String? label;
  final Widget? child;

  final Color? borderColor;

  /// Should match the color the box is on
  final Color? labelBackgroundColor;

  final double? width;

  const DescribedBox({
    super.key,
    this.label,
    this.child,
    this.borderColor,
    this.labelBackgroundColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedContainer(
          width: this.width,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInCubic,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: this.borderColor ?? Theme.of(context).primaryColor,
            ),
          ),
          child: this.child,
        ),
        if (this.label != null)
          Transform.translate(
            offset: const Offset(-2, -7),
            child: Container(
              padding: const EdgeInsets.only(right: 4.0, bottom: 2.0),
              color: labelBackgroundColor ?? Theme.of(context).cardColor,
              child: Text(
                this.label!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontSize: 10.0),
              ),
            ),
          )
      ],
    );
  }
}
