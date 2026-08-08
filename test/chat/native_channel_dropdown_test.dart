import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_username_bar.dart/native_channel_dropdown.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchChannelService channelService;
  late TwitchChatStore store;

  TwitchChannelRef ref(String id) => TwitchChannelRef(
        id: id,
        login: 'login-$id',
        displayName: 'Channel $id',
        addedAt: DateTime.utc(2026, 8, 9),
      );

  /// FakeAsync-zone Hive close dance (see native_chat_options_sheet_test).
  Future<void> closeHiveInZone(WidgetTester tester) async {
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('channel_dropdown_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    eventSubService = FakeTwitchEventSubService();
    channelService = FakeTwitchChannelService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______) =>
          eventSubService,
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      channelService: channelService,
    );
    await store.startLogin();

    /// The fake EventSub connect never emits state — settle to live so the
    /// dropdown is enabled (it disables while connecting).
    store.chatConnection = TwitchChatConnectionState.live;
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('own channel first with the You marker, shields for moderated',
      (tester) async {
    store.channels.addAll([ref('chan-1'), ref('chan-2')]);
    store.moderatedChannelIds.add('chan-2');

    await tester.pumpWidget(wrap(const Column(children: [NativeChannelDropdown()])));
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    /// Own first (button + open menu both render the selected item), then
    /// the added channels in list order.
    expect(find.text('Kounex'), findsWidgets);
    expect(find.text('You'), findsWidgets);
    expect(find.text('Channel chan-1'), findsOneWidget);
    expect(find.text('Channel chan-2'), findsOneWidget);
    expect(find.byIcon(Icons.shield), findsOneWidget);
    expect(find.text('Add chat…'), findsOneWidget);
  });

  testWidgets('selecting a channel calls selectChannel', (tester) async {
    /// try/finally: a failed expectation must still run the FakeAsync-zone
    /// Hive close dance — the interactions below persist to the settings
    /// box, and skipping the dance deadlocks tearDown's harness.close().
    try {
      store.channels.add(ref('chan-1'));

      await tester.pumpWidget(wrap(const Column(children: [NativeChannelDropdown()])));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Channel chan-1').last);
      await tester.pumpAndSettle();

      expect(store.selectedChannelId, 'chan-1');
      expect(eventSubService.lastSwitchBroadcasterId, 'chan-1');

      /// The real service emits connected once the new subs are up — the
      /// fake doesn't, so settle to live (the dropdown disables during a
      /// switch).
      store.chatConnection = TwitchChatConnectionState.live;
      await tester.pump();

      /// Switching back renders own as the selected value again.
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kounex').last);
      await tester.pumpAndSettle();

      expect(store.selectedChannelId, isNull);
      expect(eventSubService.lastSwitchBroadcasterId, 'user-1');
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets('long-press asks for confirmation and removes the channel',
      (tester) async {
    try {
      store.channels.add(ref('chan-1'));

      await tester.pumpWidget(wrap(const Column(children: [NativeChannelDropdown()])));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Channel chan-1').last);
      await tester.pumpAndSettle();

      expect(find.text('Remove chat?'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(store.channels, isEmpty);
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets('removing the selected channel falls back to own',
      (tester) async {
    try {
      await store.addChannel(ref('chan-1'));
      expect(store.selectedChannelId, 'chan-1');

      /// addChannel switched (connecting) — settle to live so the
      /// dropdown is enabled.
      store.chatConnection = TwitchChatConnectionState.live;

      await tester.pumpWidget(wrap(const Column(children: [NativeChannelDropdown()])));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Channel chan-1').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(store.selectedChannelId, isNull);
      expect(eventSubService.lastSwitchBroadcasterId, 'user-1');
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets('the Add chat entry opens the add-chat sheet', (tester) async {
    await tester.pumpWidget(wrap(const Column(children: [NativeChannelDropdown()])));
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add chat…').last);
    await tester.pumpAndSettle();

    expect(find.text('Add chat'), findsOneWidget);

    /// The entry is an action, not a selection — own stays selected.
    expect(store.selectedChannelId, isNull);
  });

  testWidgets('disabled while a channel switch is in flight', (tester) async {
    await tester.pumpWidget(wrap(const Column(children: [NativeChannelDropdown()])));
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .onChanged,
      isNotNull,
    );

    store.chatConnection = TwitchChatConnectionState.connecting;
    await tester.pump();

    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .onChanged,
      isNull,
    );
  });
}
