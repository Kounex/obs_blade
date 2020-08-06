import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/confirmation.dart';

class EditConnectionDialog extends StatefulWidget {
  final Connection connection;

  EditConnectionDialog({@required this.connection});

  @override
  _EditConnectionDialogState createState() => _EditConnectionDialogState();
}

class _EditConnectionDialogState extends State<EditConnectionDialog> {
  TextEditingController _name;
  TextEditingController _ip;
  TextEditingController _port;
  TextEditingController _pw;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.connection.name);
    _ip = TextEditingController(text: widget.connection.ip);
    _port = TextEditingController(text: widget.connection.port.toString());
    _pw = TextEditingController(text: widget.connection.pw);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
            Text('Edit Connection'),
            CupertinoButton(
              child: Text(
                'Delete',
                style: TextStyle(color: CupertinoColors.destructiveRed),
              ),
              onPressed: () {
                showCupertinoDialog(
                  context: context,
                  builder: (context) => ConfirmationDialog(
                    title: 'Delete Connection',
                    body:
                        'Are you sure you want to delete this connection? This action can\'t be undone!',
                    isYesDestructive: true,
                    onOk: () {
                      Navigator.of(context).pop();
                      widget.connection.delete();
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          Text(
              'Change the following information to change your saved connection'),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CupertinoTextField(
              controller: _name,
              placeholder: 'Name',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: CupertinoTextField(
                    controller: _ip,
                    placeholder: 'IP',
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: CupertinoTextField(
                      controller: _port,
                      placeholder: 'Port',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        WhitelistingTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CupertinoTextField(
              controller: _pw,
              placeholder: 'Password',
            ),
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
            Navigator.of(context).pop();
            widget.connection.name = _name.text;
            widget.connection.ip = _ip.text;
            widget.connection.port = int.parse(_port.text);
            widget.connection.pw = _pw.text;
            widget.connection.save();
          },
        ),
      ],
    );
  }
}
