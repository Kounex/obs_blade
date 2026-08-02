import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'mock_parts.dart';

/// Minimal mock of the Studio Mode config element: a scene dropdown row and
/// a toggle row
class StudioModeConfigPreview extends StatelessWidget {
  const StudioModeConfigPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 28.0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Expanded(child: MockBar(height: 6.0)),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                CupertinoIcons.chevron_down,
                size: 12.0,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Expanded(child: MockBar(height: 6.0)),
            const SizedBox(width: AppSpacing.md),
            Container(
              width: 32.0,
              height: 18.0,
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: AppRadius.pill,
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: MockCircle(size: 14.0, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
