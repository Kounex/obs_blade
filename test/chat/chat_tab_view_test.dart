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
import 'package:obs_blade/utils/routing_helper.dart';
import 'package:obs_blade/views/chat/chat_view.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    cupertinoOverrideTheme: const CupertinoThemeData(),

    /// The app theme always sets this (lib/app.dart) and the translucent
    /// nav bar wrapper non-Apple branch force-unwraps it
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: child,
);

void main() {
  test('chat tab routing is wired (enum, name, icon, routes)', () {
    expect(Tabs.Chat.name, 'Chat');
    expect(Tabs.Chat.icon, CupertinoIcons.chat_bubble_2_fill);
    expect(Tabs.Chat.routes, same(RoutingHelper.chatTabRoutes));
    expect(ChatTabRoutingKeys.Landing.route, '/tabs/chat');
    expect(ChatTabRoutingKeys.Pro.route, '/tabs/chat/pro');
    expect(
      RoutingHelper.chatTabRoutes.keys,
      containsAll(['/tabs/chat', '/tabs/chat/pro']),
    );
  });

  group('ChatView', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late ProStore proStore;

    Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chat_tab_view');
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

    testWidgets('renders chat standalone (no OBS stores registered)', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ChatView()));
      await tester.pump();

      /// Nav bar title + the no-config empty state: chat is usable before
      /// any OBS session exists
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Twitch Chat'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('upsell resolves on the chat tab navigator', (tester) async {
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

            /// The app theme always sets this (lib/app.dart) and the
            /// translucent nav bar wrapper non-Apple branch force-unwraps it
            appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
            extensions: const [
              AppStatusColors.standard,
              AppTextColors.standard,
            ],
          ),
          initialRoute: ChatTabRoutingKeys.Landing.route,
          onGenerateRoute: (settings) {
            if (settings.name == ChatTabRoutingKeys.Landing.route) {
              return CupertinoPageRoute(
                builder: (_) => const ChatView(),
                settings: settings,
              );
            }
            pushed = settings.name;
            return CupertinoPageRoute(
              builder: (_) => const Scaffold(body: Text('PRO STUB')),
              settings: settings,
            );
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Explore Pro'));
      await tester.pump();

      /// The push resolves in the first frame; the incoming Cupertino
      /// page only enters the tree once its transition builds
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushed, ChatTabRoutingKeys.Pro.route);
      expect(find.text('PRO STUB'), findsOneWidget);
    });
  });
}
