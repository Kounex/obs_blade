import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/base_card.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  final EdgeInsetsGeometry paddingChild;

  SwitcherCard(
      {@required this.title,
      @required this.child,
      this.paddingChild = const EdgeInsets.all(0)});

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = context.watch<HomeStore>();

    return BaseCard(
      paddingChild: this.paddingChild,
      titleWidget: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: Align(
          key: Key(this.title),
          alignment: Alignment.centerLeft,
          child: Text(
            this.title,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
      ),
      trailingTitleWidget: CupertinoButton(
        padding: const EdgeInsets.all(0),
        child: Container(
          width: 60.0,
          child: Text(
            landingStore.manualMode ? 'Auto' : 'Manual',
            textAlign: TextAlign.center,
          ),
        ),
        onPressed: () => landingStore.toggleManualMode(),
      ),
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
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
    );
  }
}
