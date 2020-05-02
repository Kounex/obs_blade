import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:obs_station/app.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_station/types/enums/hive_keys.dart';

import 'models/connection.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<Connection>(HiveKeys.SAVED_CONNECTIONS.name);
  runApp(App());
}
