import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../shared/design/design.dart';
import '../../../stores/pro_store.dart';
import '../../settings/widgets/accent_icon_tile.dart';

/// Paywall hero: Pro branding on the app accent.
///
/// Hidden debug toggle: long-press the logo tile to flip
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
          child: const AccentIconTile(
            icon: CupertinoIcons.bolt_fill,
            size: 88.0,
            iconSize: 44.0,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'OBS Blade Pro',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Native chat, moderation and more — built for your pocket.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
