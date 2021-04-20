import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
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

  /// Enums which can also be persisted as part of the models
  Hive.registerAdapter(ChatTypeAdapter());
  Hive.registerAdapter(SceneItemTypeAdapter());

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

  /// Open Hive boxes which are not bound to models
  await Hive.openBox(
    HiveKeys.Settings.name,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
  );

  runApp(
    LifecycleWatcher(
      app: App(),
    ),
  );
}
