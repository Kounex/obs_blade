import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/logs.dart';
import 'package:obs_blade/views/settings/logs/logs.dart';

import '../persistence/support/hive_test_harness.dart';

/// Host that rebuilds the view on demand, simulating any ancestor rebuild
/// (rotation, theme swap, scaffold re-layout) - build must be pure
class _Host extends StatefulWidget {
  const _Host({super.key});

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  void poke() => setState(() {});

  @override
  Widget build(BuildContext context) => LogsView();
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Widget wrap(Key hostKey) => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
      ),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: _Host(key: hostKey),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('logs_view_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    GetIt.instance.registerLazySingleton<LogsStore>(() => LogsStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('log filters survive rebuilds of the logs view', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final hostKey = GlobalKey<_HostState>();
    await tester.pumpWidget(wrap(hostKey));
    await tester.pumpAndSettle();

    GetIt.instance<LogsStore>().setLogLevel(LogLevel.Warning);
    await tester.pump();

    /// Any ancestor rebuild (rotation, theme swap, ...) re-runs the view's
    /// build - it must not wipe the active filters
    hostKey.currentState!.poke();
    await tester.pump();

    expect(GetIt.instance<LogsStore>().logLevel, LogLevel.Warning);
  });
}
