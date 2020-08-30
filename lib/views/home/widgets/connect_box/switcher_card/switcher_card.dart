import 'package:flutter/material.dart';

import '../../../../../shared/general/base_card.dart';

class SwitcherCard extends StatelessWidget {
  final String title;
  final Widget child;

  final bool noPaddingChild;

  SwitcherCard(
      {@required this.title, @required this.child, this.noPaddingChild = true});

  @override
  Widget build(BuildContext context) {
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
