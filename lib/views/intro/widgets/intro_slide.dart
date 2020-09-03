import 'package:flutter/material.dart';
import 'package:obs_blade/views/intro/intro.dart';

class IntroSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).padding.bottom + kIntroControlsBottomPadding,
      ),
      child: Center(
        child: Text('WTF'),
      ),
    );
  }
}
