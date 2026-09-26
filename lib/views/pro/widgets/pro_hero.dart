import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../models/enums/chat_type.dart';
import '../../../shared/design/design.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/pro_ids.dart';
import '../../../utils/styling_helper.dart';
import '../../dashboard/widgets/obs_widgets/stream_chat/combined_chat_icon.dart';
import 'pro_palette.dart';

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
            alignment: Alignment.center,
            children: [
              /// Platform-colour halo turning slowly behind the mark
              const Positioned(
                left: -34.0,
                top: -34.0,
                right: -34.0,
                bottom: -34.0,
                child: _PlatformHalo(),
              ),
              Container(
                width: 96.0,
                height: 96.0,
                decoration: ShapeDecoration(
                  /// Scene-button idiom: weak tint fill, full-color ring -
                  /// squircle (same ContinuousRectangleBorder contract as the
                  /// decorative icon tiles, size x 0.38)
                  color: Color.alphaBlend(
                    accent.withValues(alpha: 0.12),
                    Theme.of(context).scaffoldBackgroundColor,
                  ),
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
                  child: _ProBadge(accent: accent),
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
          'Twitch, Kick and YouTube chat - native, combined and moderated from your pocket.',
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
        const SizedBox(height: AppSpacing.md),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _PlatformChip(type: ChatType.Twitch),
            _PlatformChip(type: ChatType.Kick),
            _PlatformChip(type: ChatType.YouTube),
          ],
        ),
      ],
    );
  }
}

/// Soft sweep of the three platform hues, blurred into a halo and turning
/// once per [_period]. Static under reduced motion.
class _PlatformHalo extends StatefulWidget {
  const _PlatformHalo();

  static const Duration _period = Duration(seconds: 12);

  @override
  State<_PlatformHalo> createState() => _PlatformHaloState();
}

class _PlatformHaloState extends State<_PlatformHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _PlatformHalo._period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduce(this.context)) {
      this._controller.stop();
    } else if (!this._controller.isAnimating) {
      this._controller.repeat();
    }
  }

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double alpha = ProPalette.darkSurface(context) ? 0.55 : 0.35;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 22.0, sigmaY: 22.0),
          child: RotationTransition(
            turns: this._controller,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    ProPalette.twitch.withValues(alpha: alpha),
                    ProPalette.kick.withValues(alpha: alpha * 0.8),
                    ProPalette.youtube.withValues(alpha: alpha),
                    ProPalette.twitch.withValues(alpha: alpha),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Platform name with its mark, tinted in the platform's colour
class _PlatformChip extends StatelessWidget {
  final ChatType type;

  const _PlatformChip({required this.type});

  @override
  Widget build(BuildContext context) {
    final Color ink = ProPalette.platformInk(context, this.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: ProPalette.brand(this.type).withValues(alpha: 0.14),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: ProPalette.brand(this.type).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chatTypeIcon(context, this.type, size: 16.0, color: ink),
          const SizedBox(width: 6.0),
          Text(
            this.type.text,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The hero's stacked badge - a small accent-gradient pill with a card-color
/// ring (separates it from the vortex behind, coin-edge style) and a soft
/// accent glow for the "fancy" lift.
class _ProBadge extends StatelessWidget {
  final Color accent;

  const _ProBadge({required this.accent});

  @override
  Widget build(BuildContext context) {
    final Color deep = Color.lerp(this.accent, Colors.black, 0.35)!;
    final Color textColor = StylingHelper.surroundingAwareAccent(
      surroundingColor: this.accent,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [this.accent, deep],
        ),
        borderRadius: AppRadius.pill,
        border: Border.all(color: Theme.of(context).cardColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: this.accent.withValues(alpha: 0.45),
            blurRadius: 8.0,
            spreadRadius: 0.5,
          ),
        ],
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
    );
  }
}
