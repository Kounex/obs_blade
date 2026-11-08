import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design.dart';
import '../../../utils/styling_helper.dart';

/// The "★ PRO" pill: an accent-gradient flag for Pro features. [stacked]
/// adds a card-color ring and a soft accent glow, for sitting on artwork
/// (the paywall hero's coin-edge look); plain it sits in a header, next to
/// a feature's title.
class ProBadge extends StatelessWidget {
  /// Defaults to the theme's accent (the paywall's brand color)
  final Color? accent;
  final bool stacked;

  const ProBadge({super.key, this.accent, this.stacked = false});

  @override
  Widget build(BuildContext context) {
    final Color accent =
        this.accent ?? Theme.of(context).buttonTheme.colorScheme!.secondary;
    final Color deep = Color.lerp(accent, Colors.black, 0.35)!;
    final Color textColor = StylingHelper.surroundingAwareAccent(
      surroundingColor: accent,
    );

    return Semantics(
      label: 'Pro feature',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, deep],
          ),
          borderRadius: AppRadius.pill,
          border: this.stacked
              ? Border.all(color: Theme.of(context).cardColor, width: 2.0)
              : null,
          boxShadow: this.stacked
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45),
                    blurRadius: 8.0,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.star_fill, size: 8.0, color: textColor),
            const SizedBox(width: 2.0),
            Text(
              'PRO',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                height: 1.0,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
