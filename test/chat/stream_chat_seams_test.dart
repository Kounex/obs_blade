import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    cupertinoOverrideTheme: const CupertinoThemeData(),
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: Scaffold(body: child),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late ProStore proStore;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stream_chat_seams');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await settingsBox().put(SettingsKeys.BoughtPro.name, true);
    await settingsBox().put(SettingsKeys.ProColdStartRestoreDone.name, true);

    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);
  });

  tearDown(() async {
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders the empty state without any OBS stores registered', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const StreamChat()));
    await tester.pump();

    /// Empty state = no username selected: the whole surface rendered
    /// with no DashboardStore/NetworkStore in GetIt
    expect(find.text('Twitch Chat'), findsOneWidget);
    expect(find.textContaining('No Twitch username selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('upsell pill pushes the host-provided pro route', (tester) async {
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.BoughtPro.name, false),
    );
    await tester.runAsync(
      () => settingsBox().put(
        SettingsKeys.SelectedChatEngine.name,
        ChatEngine.native,
      ),
    );

    String? pushed;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: const Scaffold(body: StreamChat(proRoute: '/test/pro')),
        onGenerateRoute: (settings) {
          pushed = settings.name;
          return CupertinoPageRoute(
            builder: (_) => const Scaffold(body: Text('PRO STUB')),
          );
        },
      ),
    );
    await tester.pump();

    expect(find.text('Explore Pro'), findsOneWidget);
    await tester.tap(find.text('Explore Pro'));
    await tester.pump();

    /// The push resolves in the first frame; the incoming Cupertino page
    /// only enters the tree once its transition builds
    await tester.pump(const Duration(milliseconds: 300));

    expect(pushed, '/test/pro');
    expect(find.text('PRO STUB'), findsOneWidget);
  });
}
