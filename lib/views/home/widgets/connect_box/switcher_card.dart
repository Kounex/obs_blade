import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../stores/views/home.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  final EdgeInsetsGeometry paddingChild;

  const SwitcherCard({
    super.key,
    required this.title,
    required this.child,
    this.paddingChild = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    HomeStore homeStore = GetIt.instance<HomeStore>();

    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;
    final bool darkSurface =
        Theme.of(context).cardColor.computeLuminance() <= 0.2;

    /// Connect-method segment (v12 user decision): deliberately NEUTRAL -
    /// no accent edge/underline, selection is carried by the thumb fill +
    /// white selected label alone (iOS-style)
    final Color segBackground = (darkSurface ? Colors.white : Colors.black)
        .withValues(alpha: 0.06);
    final Color segThumb = darkSurface
        ? Colors.white.withValues(alpha: 0.13)
        : Colors.white;

    Color segIconColor(ConnectMode mode) => homeStore.connectMode == mode
        ? textColors.textPrimary
        : textColors.textSecondary;

    return BaseCard(
      paddingChild: this.paddingChild,
      topPadding: AppSpacing.xxl,
      titleWidget: AnimatedSwitcher(
        duration: AppMotion.medium,

        /// Sequential, not simultaneous (user-ratified): the outgoing
        /// title fully fades out over the first half, then the incoming
        /// one fades in over the second half - no cross-dissolve overlap.
        /// Interval(0.5, 1.0) alone achieves this regardless of direction:
        /// applied to a forward (incoming) animation it clamps to 0 until
        /// the midpoint then ramps to 1; applied to the same entry's own
        /// reverse (outgoing) run it ramps 1 to 0 by the midpoint then
        /// clamps at 0.
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0),
          ),
          child: child,
        ),
        child: Align(
          key: ValueKey((
            homeStore.connectMode,
            homeStore.connectModeSwitchGeneration,
          )),
          alignment: Alignment.centerLeft,
          child: Text(
            this.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: CupertinoSlidingSegmentedControl<ConnectMode>(
              groupValue: homeStore.connectMode,
              backgroundColor: segBackground,
              thumbColor: segThumb,
              children: {
                ConnectMode.Autodiscover: Icon(
                  CupertinoIcons.antenna_radiowaves_left_right,
                  color: segIconColor(ConnectMode.Autodiscover),
                ),
                ConnectMode.QR: Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: segIconColor(ConnectMode.QR),
                ),
                ConnectMode.Manual: Icon(
                  CupertinoIcons.textformat,
                  color: segIconColor(ConnectMode.Manual),
                ),
              },
              onValueChanged: (mode) => homeStore.setConnectMode(mode!),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const BaseDivider(),
          AnimatedSwitcher(
            duration: AppMotion.medium,

            /// Pane switches (user-ratified): sequential fade, not a
            /// cross-dissolve - the outgoing pane fully fades out over the
            /// first half, then the incoming one fades in over the second
            /// half (same Interval(0.5, 1.0) trick as the title switcher
            /// above). The size reveal stays on its own emphasized curve
            /// across the full duration so content below the card doesn't
            /// jump; reduced motion = fade-only.
            transitionBuilder: (child, animation) {
              final CurvedAnimation curved = CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0),
              );
              Widget current = FadeTransition(opacity: curved, child: child);
              if (!AppMotion.reduce(context)) {
                current = SizeTransition(
                  sizeFactor: animation.drive(
                    Tween(
                      begin: 0.75,
                      end: 1.0,
                    ).chain(CurveTween(curve: AppMotion.emphasized)),
                  ),
                  child: current,
                );
              }
              return current;
            },
            child: this.child,
          ),
        ],
      ),
    );
  }
}
