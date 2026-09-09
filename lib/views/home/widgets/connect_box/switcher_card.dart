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
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.0, 0.25),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.emphasized,
                  ),
                ),
            child: child,
          ),
        ),
        child: Align(
          key: ValueKey(this.title),
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
            key: ValueKey(this.title),
            duration: AppMotion.medium,

            /// Pane switches (token-delta §4 delta 4): 12px rise + fade at
            /// medium + emphasized - the size reveal is kept so content
            /// below doesn't jump; reduced motion = fade-only
            transitionBuilder: (child, animation) {
              final CurvedAnimation curved = CurvedAnimation(
                parent: animation,
                curve: AppMotion.emphasized,
              );
              Widget current = FadeTransition(opacity: curved, child: child);
              if (!AppMotion.reduce(context)) {
                current = AnimatedBuilder(
                  animation: curved,
                  child: current,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0.0, (1.0 - curved.value) * 12.0),
                    child: child,
                  ),
                );
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
