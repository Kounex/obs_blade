import 'package:flutter/material.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/button.dart';
import '../../../utils/icons/jam_icons.dart';
import '../../settings/widgets/accent_icon_tile.dart';
import 'pro_benefits.dart';

/// What a Pro-only surface shows without the entitlement - the native
/// chat pane and the activity feed share it: padlock tile, what it is, a
/// taste of the other benefits (titles only, the paywall carries the full
/// copy) and "Explore Pro".
class ProLockedPane extends StatelessWidget {
  final String title;
  final String body;
  final List<ProBenefit> benefits;

  /// Paywall route on the host tab's navigator
  final String proRoute;

  const ProLockedPane({
    super.key,
    required this.title,
    required this.body,
    required this.benefits,
    required this.proRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AccentIconTile(
          icon: JamIcons.padlock,
          size: 64.0,
          iconSize: 30.0,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          this.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          this.body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),

        /// Icons stay neutral (rule 5 - the padlock tile is the pane's one
        /// accent moment; the paywall's colour is its own exception)
        for (final ProBenefit benefit in this.benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  benefit.icon,
                  size: 16.0,
                  color:
                      (Theme.of(context).extension<AppTextColors>() ??
                              AppTextColors.standard)
                          .textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    benefit.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        BaseButton(
          text: 'Explore Pro',
          onPressed: () => Navigator.of(context).pushNamed(this.proRoute),
        ),
      ],
    );
  }
}
