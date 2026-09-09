import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/design/design.dart';
import '../../../stores/pro_store.dart';

/// Paywall hero: the Pro bolt-in-squircle on the scene-tile color idiom
/// (token-delta §2.2) - full-strength accent ring, weak accent tint fill,
/// accent glyph - with the 'OBS Blade Pro' brand line underneath (the
/// nav bar above stays back-only, so the name lives here). The value
/// line follows as the pitch headline (~19/600, near-white).
///
/// Hidden debug toggle: long-press the logo to flip
/// [ProStore.setDebugOverride] (grants the entitlement locally).
/// `kDebugMode` only - the gesture isn't even attached in release builds.
class ProHero extends StatelessWidget {
  final ProStore store;

  const ProHero({super.key, required this.store});

  void _toggleDebugOverride(BuildContext context) {
    /// The observable syncs via the async box watcher, so decide the new
    /// value up front for the snackbar copy
    final bool enable = !this.store.debugOverride;
    this.store.setDebugOverride(enable);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            enable
                ? 'Debug Pro override enabled'
                : 'Debug Pro override disabled',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    /// The accent group accessor (see app.dart): brand/selection color
    final Color accent =
        Theme.of(context).buttonTheme.colorScheme!.secondary;

    return Column(
      children: [
        GestureDetector(
          onLongPress:
              kDebugMode ? () => this._toggleDebugOverride(context) : null,
          child: Container(
            width: 96.0,
            height: 96.0,
            decoration: BoxDecoration(
              /// Scene-button idiom: weak tint fill, full-color ring
              color: accent.withValues(alpha: 0.12),
              border: Border.all(color: accent, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              CupertinoIcons.bolt_fill,
              color: accent,
              size: 48.0,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'OBS Blade Pro',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color:
                    Theme.of(context).extension<AppTextColors>()!.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Native chat, moderation and more — built for your pocket.',
          textAlign: TextAlign.center,

          /// The value line is the pitch headline (token-delta §5):
          /// 19/600, near-white, tight tracking
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 19.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.19,
                height: 1.4,
                color:
                    Theme.of(context).extension<AppTextColors>()!.textPrimary,
              ),
        ),
      ],
    );
  }
}
