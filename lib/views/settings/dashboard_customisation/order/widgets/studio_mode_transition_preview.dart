import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

/// Minimal mock of the Studio Mode transition element: preview (PVW) and
/// program (PGM) frames with the transition arrow between them
class StudioModeTransitionPreview extends StatelessWidget {
  const StudioModeTransitionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;

    Widget frame(String label, {bool program = false}) => AspectRatio(
      aspectRatio: 16.0 / 9.0,
      child: Container(
        decoration: BoxDecoration(
          color: program ? accent.withValues(alpha: 0.15) : null,
          border: Border.all(
            color: program ? accent : Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: program
                  ? accent
                  : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ),
    );

    return Row(
      children: [
        Expanded(child: frame('PVW')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Icon(CupertinoIcons.arrow_right, size: 16.0, color: accent),
        ),
        Expanded(child: frame('PGM', program: true)),
      ],
    );
  }
}
