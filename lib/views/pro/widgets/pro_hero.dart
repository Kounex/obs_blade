import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'pro_badge.dart';
import '../../../shared/design/design.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/pro_ids.dart';

/// Paywall hero: the OBS Blade vortex mark (brand icon, no wordmark) in a
/// squircle on the scene-tile color idiom (token-delta §2.2) - full-strength
/// accent ring, weak accent tint fill, accent-tinted glyph - with a "PRO"
/// badge stacked at its bottom-right corner and the 'OBS Blade Pro' brand
/// line underneath (the nav bar above stays back-only, so the name lives
/// here). The value line follows as the pitch headline (~19/600, near-white).
///
/// Hidden debug toggle: long-press the logo to flip
/// [ProStore.setDebugOverride] (grants the entitlement locally).
/// `kDebugMode` only, or a release build compiled with
/// [kProReleaseTestUnlock] - the gesture isn't attached in an ordinary
/// release build.
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
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;

    return Column(
      children: [
        GestureDetector(
          onLongPress: kDebugMode || kProReleaseTestUnlock
              ? () => this._toggleDebugOverride(context)
              : null,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96.0,
                height: 96.0,
                decoration: ShapeDecoration(
                  /// Scene-button idiom: weak tint fill, full-color ring -
                  /// squircle (same ContinuousRectangleBorder contract as the
                  /// decorative icon tiles, size x 0.38)
                  color: accent.withValues(alpha: 0.12),
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(96.0 * 0.38),
                    side: BorderSide(color: accent, width: 1.5),
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/logo_vortex.png',
                    width: 52.0,
                    height: 52.0,
                    color: accent,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),

              /// Stacked "PRO" badge - anchored into the bottom-right corner
              /// (Positioned, so it doesn't inflate the Stack's own size)
              /// then nudged outward for a slight overhang via Transform,
              /// which only shifts paint, not layout - correct regardless
              /// of how wide "PRO" renders.
              Positioned(
                right: 0.0,
                bottom: 0.0,
                child: Transform.translate(
                  offset: const Offset(6.0, 4.0),
                  child: ProBadge(accent: accent, stacked: true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'OBS Blade Pro',
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: Theme.of(context).extension<AppTextColors>()!.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Native Twitch, Kick and YouTube chat - plus every supporter in one feed and your chat read out loud.',
          textAlign: TextAlign.center,

          /// The value line is the pitch headline (token-delta §5):
          /// 19/600, near-white, tight tracking
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 19.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.19,
            height: 1.4,
            color: Theme.of(context).extension<AppTextColors>()!.textPrimary,
          ),
        ),
      ],
    );
  }
}
