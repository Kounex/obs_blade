import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/settings/data_management/data_management.dart';
import 'package:obs_blade/views/settings/data_management/widgets/data_entry.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Widget wrap() => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
      ),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    home: const DataManagementView(),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('data_management_view');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    GetIt.instance.registerSingleton<TabsStore>(TabsStore());

    /// Seeded here (real async) - Hive writes inside testWidgets' fake-async
    /// zone never complete
    await Hive.box<PastStreamData>(
      HiveKeys.PastStreamData.name,
    ).add(PastStreamData()..name = 'Stream');
    await Hive.box<PastRecordData>(
      HiveKeys.PastRecordData.name,
    ).add(PastRecordData()..name = 'Recording');
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.KickUsernames.name, ['xqc']);
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.SelectedKickUsername.name, 'xqc');
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.TwitchUsernames.name, ['kounex']);
    await Hive.box<KickAuth>(HiveKeys.KickAuth.name).add(
      KickAuth(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAtMs: 0,
        scopes: const [],
      ),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Statistics clear deletes streams AND recordings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final statisticsEntry = find.ancestor(
      of: find.text('Statistics'),
      matching: find.byType(DataEntry),
    );
    await tester.ensureVisible(statisticsEntry);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: statisticsEntry, matching: find.byType(BaseButton)),
    );
    await tester.pumpAndSettle();

    /// The confirm callback clears Hive boxes (real I/O) - run it in a real
    /// zone so the writes can complete instead of hanging the suite
    await tester.runAsync(() async {
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(Hive.box<PastStreamData>(HiveKeys.PastStreamData.name), isEmpty);
    expect(Hive.box<PastRecordData>(HiveKeys.PastRecordData.name), isEmpty);
  });

  testWidgets('Kick Chats clear removes Kick channels + sign-in only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final kickEntry = find.ancestor(
      of: find.text('Kick Chats'),
      matching: find.byType(DataEntry),
    );
    await tester.ensureVisible(kickEntry);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(of: kickEntry, matching: find.byType(BaseButton)),
    );
    await tester.pumpAndSettle();

    /// The confirm callback clears Hive boxes (real I/O) - run it in a real
    /// zone so the writes can complete instead of hanging the suite
    await tester.runAsync(() async {
      await tester.tap(find.text('Yes'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    final settings = Hive.box(HiveKeys.Settings.name);
    expect(settings.get(SettingsKeys.KickUsernames.name), isNull);
    expect(settings.get(SettingsKeys.SelectedKickUsername.name), isNull);
    expect(Hive.box<KickAuth>(HiveKeys.KickAuth.name), isEmpty);

    /// Other platforms untouched
    expect(settings.get(SettingsKeys.TwitchUsernames.name), ['kounex']);
  });
}
