import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_station/models/past_stream_data.dart';
import 'package:obs_station/models/settings.dart';
import 'package:obs_station/types/enums/hive_keys.dart';

import 'models/connection.dart';

void main() async {
  await Hive.initFlutter();

  Hive.registerAdapter(ConnectionAdapter());
  Hive.registerAdapter(PastStreamDataAdapter());
  Hive.registerAdapter(SettingsAdapter());

  await Hive.openBox<Connection>(HiveKeys.SAVED_CONNECTIONS.name);
  await Hive.openBox<PastStreamData>(HiveKeys.PAST_STREAM_DATA.name);

  /// Settings is a singleton - therefore not really a use case
  /// for Hive since it persists data in a key value store manner
  /// (like tables) so you usually have several entities for each
  /// key, but since it is so fast and encrypted and eadsy to use
  /// we make sure we have an instance form the beginning and we
  /// won't add additional one, instead save the current one
  Box<Settings> settingsBox =
      await Hive.openBox<Settings>(HiveKeys.SETTINGS.name);
  if (settingsBox.length == 0) {
    await settingsBox.add(Settings());
  }

  runApp(App());
}
