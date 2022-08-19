import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/divider.dart';

import '../../../../shared/general/base/card.dart';
import '../../../../stores/views/home.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  final EdgeInsetsGeometry paddingChild;

  const SwitcherCard({
    Key? key,
    required this.title,
    required this.child,
    this.paddingChild = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = GetIt.instance<HomeStore>();

    return BaseCard(
      paddingChild: this.paddingChild,
      topPadding: 32.0,
      titleWidget: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Align(
          key: ValueKey(this.title),
          alignment: Alignment.centerLeft,
          child: Text(
            this.title,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12.0),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: CupertinoSlidingSegmentedControl<ConnectMode>(
              groupValue: landingStore.connectMode,
              children: const {
                ConnectMode.Autodiscover:
                    Icon(CupertinoIcons.dot_radiowaves_left_right),
                ConnectMode.QR: Icon(CupertinoIcons.qrcode_viewfinder),
                ConnectMode.Manual: Icon(CupertinoIcons.textformat),
              },
              onValueChanged: (mode) => landingStore.setConnectMode(mode!),
            ),
          ),
          const SizedBox(height: 12.0),
          const BaseDivider(),
          AnimatedSwitcher(
            key: ValueKey(this.title),
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation.drive(
                  Tween(begin: 0.75, end: 1.0).chain(
                    CurveTween(curve: Curves.easeOut),
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
