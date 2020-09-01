import 'package:flutter/material.dart';

class IntroSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24.0,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom,
        left: MediaQuery.of(context).padding.left + 24.0,
      ),
      child: Text('WTF'),
    );
  }
}
