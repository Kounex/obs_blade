import 'package:flutter/material.dart';
import 'package:obs_blade/shared/animator/fader.dart';

class ResultEntry extends StatelessWidget {
  final String result;

  ResultEntry({@required this.result}) : assert(result != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 24.0, right: 24.0),
      alignment: Alignment.center,
      height: 150.0,
      child: Fader(
        child: Text(
          '${this.result}\n\nPull down to try again!',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
