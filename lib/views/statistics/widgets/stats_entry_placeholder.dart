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
      scaleFrom: 0.985,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64.0,
                height: 64.0,

                /// Decorative empty-state disc - neutral per token-delta
                /// rule 5 (doesn't spend a color group)
                decoration: BoxDecoration(
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withValues(alpha: 0.07),
                  borderRadius: AppRadius.pill,
                ),
                child: Icon(
                  this.icon,
                  size: 30.0,
                  color: Theme.of(context)
                      .extension<AppTextColors>()!
                      .textSecondary,
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
