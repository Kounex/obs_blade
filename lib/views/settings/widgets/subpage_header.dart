import 'package:flutter/material.dart';

import '../../../shared/design/design.dart';
import '../../../shared/general/base/divider.dart';

/// Unified header for the settings subpages (About / FAQ / Privacy Policy):
/// a leading visual (logo image or an [AccentIconTile]) next to a
/// scale-token title with a hairline rule and optional bylines below.
///
/// Carries its own horizontal page padding so the group never touches the
/// screen edge; the loose [Flexible] keeps short titles optically centered
/// while long titles wrap inside the padded width.
class SubpageHeader extends StatelessWidget {
  /// Leading visual - logo image or an [AccentIconTile]
  final Widget visual;

  final String title;

  /// Small print under the title rule (byline, version, ...)
  final List<Widget> bylines;

  const SubpageHeader({
    super.key,
    required this.visual,
    required this.title,
    this.bylines = const [],
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle titleStyle = Theme.of(context).textTheme.titleLarge!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          this.visual,
          const SizedBox(width: AppSpacing.xl),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(this.title, style: titleStyle),
                const SizedBox(
                  width: 64.0,
                  child: BaseDivider(height: AppSpacing.sm),
                ),
                ...this.bylines,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
