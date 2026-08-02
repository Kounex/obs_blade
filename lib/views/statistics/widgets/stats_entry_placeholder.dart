import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design.dart';

class StatsEntryPlaceholder extends StatelessWidget {
  final String text;
  final IconData icon;

  const StatsEntryPlaceholder({
    super.key,
    required this.text,
    this.icon = CupertinoIcons.chart_bar,
  });

  @override
  Widget build(BuildContext context) {
    return StaggeredEntrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.0,
                height: 64.0,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadius.pill,
                ),
                child: Icon(
                  this.icon,
                  size: 30.0,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                this.text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
