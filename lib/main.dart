import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/models/hidden_scene.dart';

import 'app.dart';
import 'models/connection.dart';
import 'models/custom_theme.dart';
import 'models/enums/chat_type.dart';
import 'models/enums/scene_item_type.dart';
import 'models/hidden_scene_item.dart';
import 'models/past_stream_data.dart';
import 'types/enums/hive_keys.dart';

class LifecycleWatcher extends StatefulWidget {
  final Widget app;

  LifecycleWatcher({required this.app});

  @override
  _LifecycleWatcherState createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver {
  late AppLifecycleState _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    print(_lastLifecycleState);
  }

  @override
  Widget build(BuildContext context) => this.widget.app;
}

bool _isLogNew(LogLevel level, String entry) => !List<AppLog>.from(
    Hive.box<AppLog>(HiveKeys.AppLog.name)
        .values
        .where((log) => log.level == level)).reversed.take(5).any((prevLog) =>
    prevLog.timestampMS - DateTime.now().millisecondsSinceEpoch < 1000 &&
    prevLog.entry == entry);

void main() async {
  /// Initialize Date Formatting - using European style
  await initializeDateFormatting('de_DE', null);

  await Hive.initFlutter();

  /// Classes which represent models which teherfore get persisted
  Hive.registerAdapter(ConnectionAdapter());
  Hive.registerAdapter(PastStreamDataAdapter());
  Hive.registerAdapter(CustomThemeAdapter());
  Hive.registerAdapter(HiddenSceneItemAdapter());
  Hive.registerAdapter(HiddenSceneAdapter());
  Hive.registerAdapter(AppLogAdapter());

  /// Enums which can also be persisted as part of the models
  Hive.registerAdapter(ChatTypeAdapter());
  Hive.registerAdapter(SceneItemTypeAdapter());
  Hive.registerAdapter(LogLevelAdapter());

  /// Open Hive boxes which are coupled to HiveObjects (models)
  await Hive.openBox<Connection>(
    HiveKeys.SavedConnections.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
  await Hive.openBox<PastStreamData>(
    HiveKeys.PastStreamData.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
  await Hive.openBox<CustomTheme>(
    HiveKeys.CustomTheme.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
  await Hive.openBox<HiddenSceneItem>(
    HiveKeys.HiddenSceneItem.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
  await Hive.openBox<HiddenScene>(
    HiveKeys.HiddenScene.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
  await Hive.openBox<AppLog>(
    HiveKeys.AppLog.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );

  /// Open Hive boxes which are not bound to models
  await Hive.openBox(
    HiveKeys.Settings.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };
      runApp(
        LifecycleWatcher(
          app: App(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      if (_isLogNew(LogLevel.Error, error.toString())) {
        Hive.box<AppLog>(HiveKeys.AppLog.name).add(
          AppLog(
            DateTime.now().millisecondsSinceEpoch,
            LogLevel.Error,
            error.toString(),
            stack.toString(),
          ),
        );
      }
    },
    zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) {
      parent.print(zone, line);
      if (_isLogNew(LogLevel.Info, line)) {
        Hive.box<AppLog>(HiveKeys.AppLog.name).add(
          AppLog(
            DateTime.now().millisecondsSinceEpoch,
            LogLevel.Info,
            line,
          ),
        );
      }
    }),
  );
}
