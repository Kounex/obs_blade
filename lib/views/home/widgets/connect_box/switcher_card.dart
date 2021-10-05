import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/general/base/base_card.dart';
import '../../../../shared/general/themed/themed_cupertino_button.dart';
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
          key: Key(this.title),
          alignment: Alignment.centerLeft,
          child: Text(
            this.title,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
      ),
      trailingTitleWidget: SizedBox(
        width: 60.0,
        child: ThemedCupertinoButton(
          padding: const EdgeInsets.all(0),
          onPressed: () => landingStore.toggleManualMode(),
          text: landingStore.manualMode ? 'Auto' : 'Manual',
        ),
      ),
      child: AnimatedSwitcher(
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
    );
  }
}
