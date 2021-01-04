import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/shared/dialogs/confirmation.dart';

class AddEditUsernameDialog extends StatefulWidget {
  final Box settingsBox;
  final String username;

  AddEditUsernameDialog({
    @required this.settingsBox,
    this.username,
  });

  @override
  _AddEditUsernameDialogState createState() => _AddEditUsernameDialogState();
}

class _AddEditUsernameDialogState extends State<AddEditUsernameDialog> {
  @override
  Widget build(BuildContext context) {
    return ConfirmationDialog(
      title: '',
      body: '',
      onOk: (_) {},
    );
  }
}
