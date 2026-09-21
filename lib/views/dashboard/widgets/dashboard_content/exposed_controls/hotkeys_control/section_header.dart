import 'package:flutter/material.dart';

import '../../../../../../shared/design/design.dart';

/// Caption section header (labelSmall uppercase, letterspaced, textTertiary,
/// left-aligned with the [AppSpacing.lg] top rhythm) - the settings caption
/// contract, replacing the divider-flanked centered variant
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          this.title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).extension<AppTextColors>()!.textTertiary,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
