import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/button.dart';

import '../../../../../shared/design/design.dart';

/// Mock of the exposed controls element: caption label above two stacked
/// action buttons - plain inset-panel pattern like the other previews
/// (no punched-out fieldset border)
class ControlsPreview extends StatelessWidget {
  const ControlsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VARIOUS CONTROLS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: BaseButton(
            text: '<action-1>',
            onPressed: () {},
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: BaseButton(
            text: '<action-2>',
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
