import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/design/design.dart';
import '../../../stores/pro_store.dart';
import '../../../utils/styling_helper.dart';

/// Paywall hero: the logo carries the OBS BLADE wordmark, so it is the
/// hero's only brand mark (token-delta §5) - a product-name headline next
/// to it would be double naming (v12, user). The value line steps up as
/// the headline (~19/600, near-white).
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
    return Column(
      children: [
        GestureDetector(
          onLongPress:
              kDebugMode ? () => this._toggleDebugOverride(context) : null,
          child: Image.asset(
            StylingHelper.brightnessAwareOBSLogo(context),
            width: 72.0,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Native chat, moderation and more — built for your pocket.',
          textAlign: TextAlign.center,

          /// The value line IS the headline (token-delta §5): 19/600,
          /// near-white, tight tracking
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
