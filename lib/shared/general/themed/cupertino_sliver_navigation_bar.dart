import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemedCupertinoSliverNavigationBar extends StatelessWidget {
  final Widget largeTitle;

  const ThemedCupertinoSliverNavigationBar({
    Key? key,
    required this.largeTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverNavigationBar(
      backgroundColor: Theme.of(context).appBarTheme.color,
      largeTitle: this.largeTitle,
    );
  }
}
