import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/base_card.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  final bool noPaddingChild;

  SwitcherCard(
      {@required this.title, @required this.child, this.noPaddingChild = true});

  @override
  Widget build(BuildContext context) {
    HomeStore landingStore = context.watch<HomeStore>();

    return BaseCard(
      noPaddingChild: this.noPaddingChild,
      titleWidget: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: Container(
          // first element of the AnimatedSwitcher needs to have a key if the
          // switching widgets share the same widget type (in this case Container)
          key: Key(this.title),
          width: 150.0,
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
