import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/keyboard_number_header.dart';
import '../../../../shared/general/validation_cupertino_textfield.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/validation_helper.dart';

class EditConnectionDialog extends StatefulWidget {
  final Connection connection;

  EditConnectionDialog({@required this.connection});

  @override
  _EditConnectionDialogState createState() => _EditConnectionDialogState();
}

class _EditConnectionDialogState extends State<EditConnectionDialog> {
  CustomValidationTextEditingController _name;
  CustomValidationTextEditingController _ip;
  CustomValidationTextEditingController _port;

  TextEditingController _pw;

  FocusNode _portFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _name = CustomValidationTextEditingController(
      text: this.widget.connection.name,
      check: _nameValidator,
    );
    _ip = CustomValidationTextEditingController(
      text: this.widget.connection.ip,
      check: ValidationHelper.ipValidation,
    );
    _port = CustomValidationTextEditingController(
      text: this.widget.connection.port.toString(),
      check: ValidationHelper.portValidation,
    );

    _pw = TextEditingController(text: this.widget.connection.pw);
  }

  String _nameValidator(String name) => name.trim().length == 0
      ? 'Please provide a name!'
      : name.trim() != this.widget.connection.name &&
              Hive.box<Connection>(HiveKeys.SavedConnections.name)
                  .values
                  .any((connection) => connection.name == name)
          ? 'Name already in use!'
          : null;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Row(
        children: [
          Text('Edit Connection'),
          CupertinoButton(
            child: Text(
              'Delete',
              style: TextStyle(color: CupertinoColors.destructiveRed),
            ),
            onPressed: () {
              ModalHandler.showBaseDialog(
                context: context,
                dialogWidget: ConfirmationDialog(
                  title: 'Delete Connection',
                  body:
                      'Are you sure you want to delete this connection? This action can\'t be undone!',
                  isYesDestructive: true,
                  onOk: (_) {
                    Navigator.of(context).pop();
                    this.widget.connection.delete();
                  },
                ),
              );
            },
          ),
        ],
      ),
      content: Column(
        children: [
          Text(
              'Change the following information to change your saved connection'),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: ValidationCupertinoTextfield(
              controller: _name,
              placeholder: 'Name',
            ),
          ),
          Row(
            children: [
              Flexible(
                flex: 2,
                child: ValidationCupertinoTextfield(
                  controller: _ip,
                  placeholder: 'IP',
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: KeyboardNumberHeader(
                    focusNode: _portFocusNode,
                    child: ValidationCupertinoTextfield(
                      controller: _port,
                      focusNode: _portFocusNode,
                      placeholder: 'Port',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ),
              ),
            ],
          ),
          CupertinoTextField(
            controller: _pw,
            placeholder: 'Password',
            autocorrect: false,
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: Text('Cancel'),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          child: Text('Save'),
          onPressed: () {
            _name.submit();
            _ip.submit();
            _port.submit();

            if (_name.isValid && _ip.isValid && _port.isValid) {
              this.widget.connection.name = _name.text.trim();
              this.widget.connection.ip = _ip.text;
              this.widget.connection.port = int.parse(_port.text);
              this.widget.connection.pw = _pw.text;
              this.widget.connection.save();
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
