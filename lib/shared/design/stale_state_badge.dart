import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../stores/views/dashboard.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_text_colors.dart';

/// "LAST KNOWN STATE" marker for dashboard panes: shown while
/// [DashboardStore.obsStateStale] - values stay fully visible (never dimmed
/// or hidden); the badge and the disabled controls carry the honesty.
class StaleStateBadge extends StatelessWidget {
  const StaleStateBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Observer(
      builder: (_) => AnimatedSwitcher(
        duration: AppMotion.medium,
        child: GetIt.instance<DashboardStore>().obsStateStale
            ? Padding(
                key: const ValueKey('stale'),
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.exclamationmark_circle,
                      size: 14.0,
                      color: theme.extension<AppTextColors>()!.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'LAST KNOWN STATE - reconnecting to OBS',
                        style: theme.textTheme.labelSmall!.copyWith(
                          color: theme
                              .extension<AppTextColors>()!
                              .textSecondary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(key: ValueKey('fresh')),
      ),
    );
  }
}
