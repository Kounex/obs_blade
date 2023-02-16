import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';

import '../../../models/connection.dart';
import '../../../models/hidden_scene.dart';
import '../../../shared/dialogs/input.dart';
import '../../../stores/shared/network.dart';
import '../../../types/enums/hive_keys.dart';

class SaveEditConnectionDialog extends StatelessWidget {
  final bool newConnection;

  const SaveEditConnectionDialog({
    Key? key,
    this.newConnection = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    Box<Connection> box = Hive.box<Connection>(HiveKeys.SavedConnections.name);
    return InputDialog(
      title: '${this.newConnection ? 'Save' : 'Edit'} Connection',
      body:
          'Please choose a name for the connection so you can recognize it later on',
      inputText: networkStore.activeSession!.connection.name,
      inputPlaceholder: 'Name of the connection',
      inputCheck: (name) {
        name = name.trim();
        if (name.isEmpty) {
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

        /// Since [HiddenScene] and [HiddenSceneItem] elements are based on the
        /// connection name and host, once the user updates the connection, we need
        /// to update these elements as well to preserve the status
        if (name != networkStore.activeSession!.connection.name) {
          Hive.box<HiddenScene>(HiveKeys.HiddenScene.name)
              .values
              .forEach((hiddenScene) {
            if (hiddenScene.connectionName ==
                    networkStore.activeSession!.connection.name ||
                (hiddenScene.connectionName == null &&
                    hiddenScene.host ==
                        networkStore.activeSession!.connection.host)) {
              hiddenScene.connectionName = name;
              hiddenScene.save();
            }
          });

          Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name)
              .values
              .forEach((hiddenSceneItem) {
            if (hiddenSceneItem.connectionName ==
                    networkStore.activeSession!.connection.name ||
                (hiddenSceneItem.connectionName == null &&
                    hiddenSceneItem.host ==
                        networkStore.activeSession!.connection.host)) {
              hiddenSceneItem.connectionName = name;
              hiddenSceneItem.save();
            }
          });
        }

        /// If the challenge (or salt) is null, we didn't have to connect with a password.
        /// a user might still enter a password, we don't want this password to be
        /// saved, thats why we set it to null explicitly if thats the case
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
