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

    return BaseCard(
      paddingChild: this.paddingChild,
      topPadding: AppSpacing.xxl,
      titleWidget: AnimatedSwitcher(
        duration: AppMotion.medium,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.25),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: AppMotion.standard,
            )),
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
              children: const {
                ConnectMode.Autodiscover:
                    Icon(CupertinoIcons.antenna_radiowaves_left_right),
                ConnectMode.QR: Icon(CupertinoIcons.qrcode_viewfinder),
                ConnectMode.Manual: Icon(CupertinoIcons.textformat),
              },
              onValueChanged: (mode) => homeStore.setConnectMode(mode!),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const BaseDivider(),
          AnimatedSwitcher(
            key: ValueKey(this.title),
            duration: AppMotion.medium,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation.drive(
                  Tween(begin: 0.75, end: 1.0).chain(
                    CurveTween(curve: AppMotion.standard),
                  ),
                ),
                child: child,
              ),
            ),
            child: this.child,
          ),
        ],
      ),
    );
  }
}
