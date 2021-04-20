import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/dialogs/confirmation.dart';
import '../../../../utils/modal_handler.dart';

class DataEntry extends StatelessWidget {
  final String title;
  final String description;

  final String? customConfirmationText;
  final String? additionalConfirmationText;
  final VoidCallback? onClear;

  DataEntry({
    required this.title,
    required this.description,
    this.customConfirmationText,
    this.additionalConfirmationText,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this.title,
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(height: 12.0),
              Text(this.description),
            ],
          ),
        ),
        SizedBox(width: 24.0),
        RaisedButton(
          child: Text('Clear'),
          color: CupertinoColors.destructiveRed,
          onPressed: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: ConfirmationDialog(
              title: 'Delete ${this.title}',
              isYesDestructive: true,
              body: this.customConfirmationText ??
                  'Are you sure you want to delete all ${this.title}? This action can\'t be undone!',
              onOk: (_) => this.additionalConfirmationText != null
                  ? ModalHandler.showBaseDialog(
                      context: context,
                      dialogWidget: ConfirmationDialog(
                        title: 'Delete ${this.title}',
                        isYesDestructive: true,
                        body: this.additionalConfirmationText,
                        onOk: (_) => this.onClear?.call(),
                      ),
                    )
                  : this.onClear?.call(),
            ),
          ),
        ),
      ],
    );
  }
}
