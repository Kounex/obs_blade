import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'mock_parts.dart';

/// Minimal mock of the Scene Items panel: rows with a visibility eye and a
/// source name
class SceneItemsPreview extends StatelessWidget {
  const SceneItemsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color? iconColor = Theme.of(context).iconTheme.color;
    final Color disabledColor = Theme.of(context).disabledColor;

    Widget row({required IconData icon, Color? color, double endGap = 0.0}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(icon, size: 14.0, color: color ?? iconColor),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: MockBar(height: 7.0)),
              SizedBox(width: endGap),
            ],
          ),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row(icon: CupertinoIcons.eye, endGap: 32.0),
        row(icon: CupertinoIcons.eye_slash, color: disabledColor, endGap: 72.0),
        row(icon: CupertinoIcons.eye, endGap: 8.0),
      ],
    );
  }
}
