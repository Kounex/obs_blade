import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_station/shared/dialogs/info.dart';

import '../../utils/styling_helper.dart';
import 'flutter_modified/custom_tooltip.dart';

class QuestionMarkTooltip extends StatelessWidget {
  final String message;

  QuestionMarkTooltip({@required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => InfoDialog(
          body: this.message,
        ),
      ),
      child: Icon(StylingHelper.CUPERTINO_QUESTION_ICON),
    );
    // return CustomTooltip(
    //   message: this.message,
    //   padding: EdgeInsets.all(12.0),
    //   margin: EdgeInsets.all(32.0),
    //   preferBelow: false,
    //   verticalOffset: 2.0,
    //   waitDuration: Duration(milliseconds: 0),
    //   showDuration: Duration(seconds: 5),
    //   immediately: true,
    //   child: Icon(StylingHelper.CUPERTINO_QUESTION_ICON),
    // );
  }
}
