import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/formatted_text.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/card.dart';

class StatsContainer extends StatelessWidget {
  final String title;
  final Widget? trailing;

  /// Optional widget placed in front of the title (e.g. a live [StatusDot])
  final Widget? titleLeading;

  final List<FormattedText>? children;
  final Widget? child;

  final bool wrapWithDescribedBox;

  const StatsContainer({
    super.key,
    required this.title,
    this.children,
    this.child,
    this.trailing,
    this.titleLeading,
    this.wrapWithDescribedBox = false,
  })  : assert(child != null || children != null),
        super();

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      topPadding: 0.0,
      bottomPadding: 0.0,
      titlePadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      titleWidget: Row(
        children: [
          if (this.titleLeading != null) ...[
            this.titleLeading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(this.title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      trailingTitleWidget: this.trailing,
      paddingChild: const EdgeInsets.only(
          top: AppSpacing.lg,
          right: AppSpacing.lg,
          left: AppSpacing.lg,
          bottom: AppSpacing.xl),
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
                      AppSpacing.xl);
              double generalWidth =
                  (constraints.maxWidth - (amountInRow - 1) * AppSpacing.xl) /
                      amountInRow;
              return Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.xl,
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
