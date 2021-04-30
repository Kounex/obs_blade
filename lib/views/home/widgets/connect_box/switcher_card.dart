import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/general/base_card.dart';
import '../../../../shared/general/themed/themed_cupertino_button.dart';
import '../../../../stores/views/home.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  final EdgeInsetsGeometry paddingChild;

  SwitcherCard(
      {required this.title,
      required this.child,
      this.paddingChild = const EdgeInsets.all(0)});

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = context.read<HomeStore>();

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
      trailingTitleWidget: Container(
        width: 60.0,
        child: ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
          onPressed: () => landingStore.toggleManualMode(),
          text: landingStore.manualMode ? 'Auto' : 'Manual',
        ),
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
