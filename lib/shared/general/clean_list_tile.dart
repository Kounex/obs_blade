import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';

class CleanListTile extends StatelessWidget {
  final String title;
  final String description;

  final Widget? trailing;

  const CleanListTile({
    super.key,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this.title,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                this.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (this.trailing != null) ...[
          const SizedBox(width: AppSpacing.xxl),
          this.trailing!,
        ],
      ],
    );
  }
}
