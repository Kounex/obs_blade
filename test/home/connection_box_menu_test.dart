import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/app.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/connection_box.dart';

import '../persistence/support/hive_test_harness.dart';

/// The card's "..." opens the edit dialog straight away - it has Delete
/// itself, the Edit / Delete sheet in between is gone (2026-11-08).
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('connection_box_menu');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('"..." opens Edit Connection with Delete in it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)),
        home: Scaffold(
          body: Center(
            child: ConnectionBox(
              connection: Connection('192.168.178.20', 4455)
                ..name = 'GAMING-PC'
                ..reachable = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
    await tester.pumpAndSettle();

    expect(find.text('Edit Connection'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Edit'), findsNothing, reason: 'no action sheet');
  });
}
