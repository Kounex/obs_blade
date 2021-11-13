import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../../../../models/connection.dart';
import '../../../../models/hidden_scene.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/keyboard_number_header.dart';
import '../../../../shared/general/validation_cupertino_textfield.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/validation_helper.dart';

class EditConnectionDialog extends StatefulWidget {
  final Connection connection;

  const EditConnectionDialog({Key? key, required this.connection})
      : super(key: key);

  @override
  _EditConnectionDialogState createState() => _EditConnectionDialogState();
}

class _EditConnectionDialogState extends State<EditConnectionDialog> {
  late CustomValidationTextEditingController _name;
  late CustomValidationTextEditingController _ip;
  late CustomValidationTextEditingController _port;

  late TextEditingController _pw;

  final FocusNode _portFocusNode = FocusNode();

  bool _obscurePW = true;

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

  String? _nameValidator(String name) => name.trim().isEmpty
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
      title: SizedBox(
        height: 48.0,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            const Text('Edit Connection'),
            Positioned(
              top: -18.0,
              right: -12.0,
              child: CupertinoButton(
                child: const Text(
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
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          const Text(
              'Change the following information to change your saved connection'),
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
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
            obscureText: _obscurePW,
            suffix: Material(
              color: Colors.grey[
                  Theme.of(context).brightness == Brightness.light ? 300 : 900],
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(5.0)),
              child: IconButton(
                padding: const EdgeInsets.all(6),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  maxHeight: 32.0,
                  maxWidth: 32.0,
                ),
                onPressed: () => setState(() => _obscurePW = !_obscurePW),
                iconSize: 20.0,
                icon: Icon(
                  _obscurePW ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Cancel'),
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          child: const Text('Save'),
          onPressed: () {
            _name.submit();
            _ip.submit();
            _port.submit();

            if (_name.isValid && _ip.isValid && _port.isValid) {
              String newName = _name.text.trim();

              /// Since [HiddenScene] elements are based on the connection name and
              /// ip address, once the user updates the connection, we need to update
              /// these elements as well to preserve the status
              if (newName != this.widget.connection.name) {
                Hive.box<HiddenScene>(HiveKeys.HiddenScene.name)
                    .values
                    .forEach((hiddenScene) {
                  if (hiddenScene.connectionName ==
                      this.widget.connection.name) {
                    hiddenScene.connectionName = newName;
                    hiddenScene.save();
                  }
                });
              }

              this.widget.connection.name = newName;
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
