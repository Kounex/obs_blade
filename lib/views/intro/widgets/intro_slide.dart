import 'package:flutter/material.dart';
import 'package:obs_blade/views/intro/intro.dart';

class IntroSlide extends StatelessWidget {
  final List<Widget> content;

  IntroSlide({@required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 24.0,
        right: 24.0,
        bottom: MediaQuery.of(context).padding.bottom +
            kIntroControlsBottomPadding +
            32.0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: this.content,
      ),
    );
  }
}
