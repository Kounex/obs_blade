import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/shared/dialogs/input.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:provider/provider.dart';

class SaveEditConnectionDialog extends StatelessWidget {
  final bool newConnection;

  SaveEditConnectionDialog({this.newConnection = true});

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = context.watch<NetworkStore>();

    Box<Connection> box = Hive.box<Connection>(HiveKeys.SavedConnections.name);
    return InputDialog(
      title: (this.newConnection ? 'Save' : 'Edit') + ' Connection',
      body:
          'Please choose a name for the connection so you can recognize it later on',
      inputText: networkStore.activeSession!.connection.name,
      inputPlaceholder: 'Name of the connection',
      inputCheck: (name) {
        name = name.trim();
        if (name.length == 0) {
          return 'Please provide a name!';
        }
        if (box.values.any((connection) =>
            name != networkStore.activeSession!.connection.name &&
            connection.name == name)) {
          return 'Name already used!';
        }
        return null;
      },
      onSave: (name) {
        name = name?.trim();
        // if the challenge (or salt) is null, we didn't have to connect with a password.
        // a user might still enter a password, we don't want this password to be
        // saved, thats why we set it to null explicitly if thats the case
        if (networkStore.activeSession!.connection.challenge == null) {
          networkStore.activeSession!.connection.pw = null;
        }
        networkStore.activeSession!.connection.name = name;
        this.newConnection
            ? box.add(networkStore.activeSession!.connection)
            : networkStore.activeSession!.connection.save();
      },
    );
  }
}
