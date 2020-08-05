import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/utils/dialog_handler.dart';
import 'package:provider/provider.dart';

import '../dialogs/save_edit_connection.dart';

class GeneralActions extends StatelessWidget {
  final List<String> appBarActions = [
    'Manage Stream',
    'Save / Edit Connection'
  ];

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        CupertinoIcons.ellipsis,
        size: 32.0,
      ),
      onPressed: () => showCupertinoModalPopup(
        context: context,
        builder: (context) {
          bool newConnection =
              context.watch<NetworkStore>().activeSession.connection.name ==
                  null;
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  DialogHandler.showBaseDialog(
                    context: context,
                    dialogWidget: SaveEditConnectionDialog(
                      newConnection: newConnection,
                    ),
                  );
                },
                child: Text((newConnection ? 'Save' : 'Edit') + ' Connection'),
              )
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          );
        },
      ),
    );
    return Container(
      width: 150.0,
      alignment: Alignment.bottomRight,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: this.appBarActions[0],
          icon: Container(),
          isExpanded: true,
          selectedItemBuilder: (_) => [
            Container(
              alignment: Alignment.centerRight,
              child: Icon(
                CupertinoIcons.ellipsis,
                size: 32.0,
              ),
            )
          ],
          items: this
              .appBarActions
              .map(
                (action) => DropdownMenuItem<String>(
                  child: SizedBox(
                    width: 150.0,
                    child: Text(
                      action,
                    ),
                  ),
                  value: action,
                ),
              )
              .toList(),
          onChanged: (selection) {
            switch (selection) {
              case 'Save / Edit Connection':
                DialogHandler.showBaseDialog(
                  context: context,
                  dialogWidget: SaveEditConnectionDialog(),
                );
                break;
            }
          },
        ),
      ),
    );
  }
}
