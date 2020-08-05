import 'package:flutter/material.dart';

class DialogHandler {
  static Future<T> showBaseDialog<T>(
          {@required BuildContext context,
          @required Widget dialogWidget}) async =>
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => dialogWidget,
      );
}
