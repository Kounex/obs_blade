import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../shared/general/clean_list_tile.dart';

import '../../../../shared/dialogs/confirmation.dart';
import '../../../../utils/modal_handler.dart';

class DataEntry extends StatelessWidget {
  final String title;
  final String description;

  final String? customConfirmationText;
  final String? additionalConfirmationText;
  final VoidCallback? onClear;

  const DataEntry({
    Key? key,
    required this.title,
    required this.description,
    this.customConfirmationText,
    this.additionalConfirmationText,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CleanListTile(
      title: this.title,
      description: this.description,
      trailing: BaseButton(
        text: 'Clear',
        isDestructive: true,
        onPressed: () => ModalHandler.showBaseDialog(
          context: context,
          dialogWidget: ConfirmationDialog(
            title: 'Delete ${this.title}',
            isYesDestructive: true,
            body: this.customConfirmationText ??
                'Are you sure you want to delete all ${this.title}? This action can\'t be undone!',
            onOk: (_) => this.additionalConfirmationText != null
                ? Future.delayed(
                    ModalHandler.transitionDelayDuration,
                    () => ModalHandler.showBaseDialog(
                      context: context,
                      dialogWidget: ConfirmationDialog(
                        title: 'Delete ${this.title}',
                        isYesDestructive: true,
                        body: this.additionalConfirmationText,
                        onOk: (_) => this.onClear?.call(),
                      ),
                    ),
                  )
                : this.onClear?.call(),
          ),
        ),
      ),
    );
  }
}
