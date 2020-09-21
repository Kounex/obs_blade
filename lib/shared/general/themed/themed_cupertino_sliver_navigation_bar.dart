import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemedCupertinoSliverNavigationBar extends StatelessWidget {
  final Widget largeTitle;

  ThemedCupertinoSliverNavigationBar({@required this.largeTitle});

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverNavigationBar(
      backgroundColor: Theme.of(context).appBarTheme.color,
      largeTitle: this.largeTitle,
    );
  }
}
