import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'models/app_log.dart';
import 'models/connection.dart';
import 'models/custom_theme.dart';
import 'models/enums/chat_type.dart';
import 'models/enums/log_level.dart';
import 'models/enums/scene_item_type.dart';
import 'models/hidden_scene.dart';
import 'models/hidden_scene_item.dart';
import 'models/past_stream_data.dart';
import 'models/purchased_tip.dart';
import 'purchase_base.dart';
import 'stores/shared/network.dart';
import 'stores/shared/tabs.dart';
import 'stores/views/dashboard.dart';
import 'stores/views/home.dart';
import 'stores/views/intro.dart';
import 'stores/views/logs.dart';
import 'stores/views/statistics.dart';
import 'types/enums/hive_keys.dart';
import 'utils/general_helper.dart';

class LifecycleWatcher extends StatefulWidget {
  final Widget app;

  const LifecycleWatcher({Key? key, required this.app}) : super(key: key);

  @override
  _LifecycleWatcherState createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher>
    with WidgetsBindingObserver {
  late AppLifecycleState _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastLifecycleState = state;
    GeneralHelper.advLog(_lastLifecycleState);
  }

  @override
  Widget build(BuildContext context) => this.widget.app;
}

void _initializePurchases() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
  }
}

void _initializeStores() {
  /// Shared stores used app-wide
  GetIt.instance.registerLazySingleton<NetworkStore>(() => NetworkStore());
  GetIt.instance.registerLazySingleton<TabsStore>(() => TabsStore());

  /// View stores designated for specific views
  GetIt.instance.registerLazySingleton<IntroStore>(() => IntroStore());
  GetIt.instance.registerLazySingleton<HomeStore>(() => HomeStore());
  GetIt.instance.registerLazySingleton<DashboardStore>(() => DashboardStore());
  GetIt.instance
      .registerLazySingleton<StatisticsStore>(() => StatisticsStore());
  GetIt.instance.registerLazySingleton<LogsStore>(() => LogsStore());
}

Future<void> _initializeHive() async {
  await Hive.initFlutter();

  /// Classes which represent models which therefore get persisted
  Hive.registerAdapter(ConnectionAdapter());
  Hive.registerAdapter(PastStreamDataAdapter());
  Hive.registerAdapter(CustomThemeAdapter());
  Hive.registerAdapter(HiddenSceneItemAdapter());
  Hive.registerAdapter(HiddenSceneAdapter());
  Hive.registerAdapter(AppLogAdapter());
  Hive.registerAdapter(PurchasedTipAdapter());

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
  await Hive.openBox<PurchasedTip>(
    HiveKeys.PurchasedTip.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );

  /// Open Hive boxes which are not bound to models
  await Hive.openBox(
    HiveKeys.Settings.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );
}

bool _isLogNew(List<LogLevel> level, String entry) => !List<AppLog>.from(
        Hive.box<AppLog>(HiveKeys.AppLog.name)
            .values
            .where((log) => level.contains(log.level)))
    .reversed
    .take(5 * level.length)
    .any((prevLog) =>
        DateTime.now().millisecondsSinceEpoch - prevLog.timestampMS < 10000 &&
        prevLog.entry == entry);

void _logging(String line) {
  String? stack;

  LogLevel level = LogLevel.Info;
  bool shouldLog = true;
  bool manually = false;

  Iterable<LogLevel> lineLevel =
      LogLevel.values.where((level) => line.startsWith(level.prefix));

  if (lineLevel.isNotEmpty) {
    manually = true;
    level = lineLevel.first;
    line = line.split(level.prefix)[1];

    shouldLog = line.startsWith('[ON]');

    line = line.split(shouldLog ? '[ON]' : '[OFF]')[1].trim();

    if (line.contains('[STACK]')) {
      List<String> temp = line.split('[STACK]');
      String stack = temp[1].trim();

      if (stack.length > 1024) {
        stack = stack.substring(0, 1024) + '...';
      }

      line = temp[0].trim();
      stack = stack;
    }
  }

  if (shouldLog &&
      _isLogNew([LogLevel.Info, LogLevel.Warning, LogLevel.Error], line)) {
    Hive.box<AppLog>(HiveKeys.AppLog.name).add(
      AppLog(
        DateTime.now().millisecondsSinceEpoch,
        level,
        line,
        stack,
        manually,
      ),
    );
  }
}

void main() async {
  /// Initialize Date Formatting - using European style
  await initializeDateFormatting('de_DE');

  /// Initialize Purchases
  _initializePurchases();

  /// Create all store objects and make them available in the app (DI)
  _initializeStores();

  /// Create all hive objects with references to the persistant boxes
  await _initializeHive();

  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
      };
      runApp(
        const LifecycleWatcher(
          app: PurchaseBase(
            child: App(),
          ),
        ),
      );
    },
    (Object error, StackTrace stack) => _logging('$error\n[STACK]\n$stack'),
    zoneSpecification: ZoneSpecification(
      // handleUncaughtError: (self, parent, zone, error, stackTrace) =>
      //     _logging('$error\n[STACK]\n$stackTrace'),
      print: (self, parent, zone, line) {
        /// First print it out to see them while debugging
        parent.print(zone, line);

        _logging(line);
      },
    ),
  );
}
