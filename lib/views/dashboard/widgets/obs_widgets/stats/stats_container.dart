import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/formatted_text.dart';

import '../../../../../shared/general/base/card.dart';

class StatsContainer extends StatelessWidget {
  final String title;
  final Widget? trailing;

  final List<FormattedText>? children;
  final Widget? child;

  final double? elevation;

  final bool wrapWithDescribedBox;

  const StatsContainer({
    Key? key,
    required this.title,
    this.children,
    this.child,
    this.trailing,
    this.elevation,
    this.wrapWithDescribedBox = false,
  })  : assert(child != null || children != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      topPadding: 0.0,
      bottomPadding: 0.0,
      elevation: this.elevation,
      titlePadding: const EdgeInsets.symmetric(
        horizontal: 18.0,
        vertical: 12.0,
      ),
      titleWidget:
          Text(this.title, style: Theme.of(context).textTheme.titleLarge),
      trailingTitleWidget: this.trailing,
      paddingChild: const EdgeInsets.only(
          top: 18.0, right: 18.0, left: 18.0, bottom: 24.0),
      centerChild: false,
      child: this.child ??
          LayoutBuilder(
            builder: (context, constraints) {
              int amountInRow = constraints.maxWidth ~/
                  (this
                          .children!
                          .reduce((value, current) =>
                              value.width >= current.width ? value : current)
                          .width +
                      24.0);
              double generalWidth =
                  (constraints.maxWidth - (amountInRow - 1) * 24) / amountInRow;
              return Wrap(
                spacing: 24.0,
                runSpacing: 24.0,
                children: this
                    .children!
                    .map(
                      (formattedText) => FormattedText(
                        label: formattedText.label,
                        text: formattedText.text,
                        width: generalWidth,
                        unit: formattedText.unit,
                      ),
                    )
                    .toList(),
              );
            },
          ),
    );
  }
}
