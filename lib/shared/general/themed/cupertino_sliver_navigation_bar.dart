import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class ThemedCupertinoSliverNavigationBar extends StatelessWidget {
  final Widget largeTitle;

  const ThemedCupertinoSliverNavigationBar({
    super.key,
    required this.largeTitle,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverNavigationBar(
      backgroundColor: StylingHelper.isApple(context)
          ? Theme.of(context).appBarTheme.backgroundColor
          : Theme.of(context).appBarTheme.backgroundColor!.withOpacity(1.0),
      largeTitle: this.largeTitle,
    );
  }
}
