import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/checkbox.dart';
import 'package:obs_blade/shared/general/base/dropdown.dart';

import '../../../../../shared/design/design.dart';

/// Mirrors [StudioModeCheckbox] + [TransitionControls] with the same leaf
/// widgets the live dashboard uses — static, non-interactive.
class StudioModeConfigPreview extends StatelessWidget {
  const StudioModeConfigPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: BaseCheckbox(
              value: true,
              text: 'Studio Mode',
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: null,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: BaseDropdown<String>(
                  value: 'Fade',
                  items: [
                    BaseDropdownItem(value: 'Fade', text: 'Fade'),
                  ],
                  label: 'Transition',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '300 ms',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
