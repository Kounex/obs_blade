import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../utils/modal_handler.dart';
import '../design/design.dart';
import '../dialogs/info.dart';

class QuestionMarkTooltip extends StatelessWidget {
  final String message;

  const QuestionMarkTooltip({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
        onTap: () => ModalHandler.showBaseDialog(
              context: context,
              barrierDismissible: true,
              dialogWidget: InfoDialog(
                body: this.message,
              ),
            ),

        /// Padding widens the hit area to a >= 44pt tap target
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(
            CupertinoIcons.question_circle,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ));
  }
}
