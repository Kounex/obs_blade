import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../shared/general/column_separated.dart';
import 'data_entry.dart';

class DataBlock extends StatelessWidget {
  final List<DataEntry> dataEntries;

  /// Section caption rendered above the card (caption style, uppercase)
  final String? caption;

  /// Paints the card as the isolated danger zone (destructive hairline
  /// border + tinted caption)
  final bool danger;

  const DataBlock({
    super.key,
    required this.dataEntries,
    this.caption,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color? dangerColor = this.danger
        ? Theme.of(context).extension<AppStatusColors>()!.recording
        : null;

    return BaseCard(
      above: this.caption != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Row(
                children: [
                  if (this.danger) ...[
                    Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 11.0,
                      color: dangerColor,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    this.caption!.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: dangerColor ??
                              Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ),
                ],
              ),
            )
          : null,
      paintBorder: this.danger,
      borderColor: dangerColor?.withOpacity(0.6),
      topPadding: 8.0,
      bottomPadding: 12.0,
      child: ColumnSeparated(
        paddingSeparator: const EdgeInsets.symmetric(vertical: 16.0),
        children: this.dataEntries,
      ),
    );
  }
}
