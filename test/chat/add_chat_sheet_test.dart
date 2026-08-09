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
import 'package:obs_blade/types/classes/twitch/twitch_channel_search_result.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/add_chat_sheet.dart';

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

  TwitchChannelSearchResult result(
    String id, {
    int followers = 0,
    bool live = false,
  }) =>
      TwitchChannelSearchResult(
        id: id,
        login: 'login-$id',
        displayName: 'Channel $id',
        followerCount: followers,
        isLive: live,
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

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(wrap(AddChatSheet(channelService: channelService)));
    await tester.pumpAndSettle();
  }

  Future<void> runSearch(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('add_chat_sheet_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    authService.tokenScopes = const [
      'user:read:chat',
      'user:read:follows',
      'moderator:read:moderated_channels',
    ];
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

    /// Login itself fetches the moderated channels (Task 7) — reset the
    /// counters so each test counts only the sheet's own calls.
    channelService.moderatedCalls = 0;
    channelService.followedCalls = 0;
    channelService.searchCalls = 0;
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

  testWidgets('empty query loads the moderated and followed sections',
      (tester) async {
    channelService.moderatedChannels = [ref('mod-1')];
    channelService.followedChannels = [ref('fol-1'), ref('fol-2')];

    await pumpSheet(tester);

    expect(find.text('Channels you moderate'), findsOneWidget);
    expect(find.text('Channels you follow'), findsOneWidget);
    expect(find.text('Channel mod-1'), findsOneWidget);
    expect(find.text('Channel fol-1'), findsOneWidget);
    expect(find.text('Channel fol-2'), findsOneWidget);
    expect(channelService.moderatedCalls, 1);
    expect(channelService.followedCalls, 1);
    expect(channelService.lastModeratedUserId, 'user-1');
    expect(channelService.lastFollowedUserId, 'user-1');
    expect(channelService.searchCalls, 0);

    /// Full-scope token — no re-login CTA.
    expect(find.text('Re-login'), findsNothing);
  });

  testWidgets('search is debounced (~300 ms) and renders results',
      (tester) async {
    channelService.searchResults = [
      result('s-1', followers: 1500, live: true),
      result('s-2'),
    ];

    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'someone');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(channelService.searchCalls, 0);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(channelService.searchCalls, 1);
    expect(channelService.lastQuery, 'someone');
    expect(find.text('Channel s-1'), findsOneWidget);
    expect(find.text('Channel s-2'), findsOneWidget);
    expect(find.textContaining('@login-s-1'), findsOneWidget);
    expect(find.textContaining('1.5k followers'), findsOneWidget);
    expect(find.byKey(const Key('add-chat-live-s-1')), findsOneWidget);
    expect(find.byKey(const Key('add-chat-live-s-2')), findsNothing);

    /// An active query replaces the quick-pick sections.
    expect(find.text('Channels you moderate'), findsNothing);
    expect(find.text('Channels you follow'), findsNothing);
  });

  testWidgets('tapping a result adds the channel and closes the sheet',
      (tester) async {
    /// try/finally: a failed expectation must still run the FakeAsync-zone
    /// Hive close dance — adding persists to the settings box, and skipping
    /// the dance deadlocks tearDown's harness.close().
    try {
      channelService.searchResults = [result('s-1')];

      /// Through the real entry point so the close-on-add is exercised too.
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showAddChatSheet(
                    context,
                    channelService: channelService,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await runSearch(tester, 'someone');
      await tester.tap(find.text('Channel s-1'));
      await tester.pumpAndSettle();

      expect(store.channels.map((channel) => channel.id), contains('s-1'));
      expect(store.selectedChannelId, 's-1');
      expect(eventSubService.lastSwitchBroadcasterId, 's-1');
      expect(find.byType(AddChatSheet), findsNothing);
    } finally {
      await closeHiveInZone(tester);
    }
  });

  testWidgets('already-added and own channels render checked and disabled',
      (tester) async {
    store.channels.add(ref('s-1'));
    channelService.searchResults = [
      result('s-1'),
      result('s-2'),
      result('user-1'),
    ];

    await pumpSheet(tester);
    await runSearch(tester, 'someone');

    /// s-1 (already added) and user-1 (own channel) are checked off.
    expect(find.byIcon(Icons.check), findsNWidgets(2));

    await tester.tap(find.text('Channel s-1'));
    await tester.pumpAndSettle();
    expect(store.channels.length, 1);
    expect(eventSubService.lastSwitchBroadcasterId, isNull);

    await tester.tap(find.text('Channel user-1'));
    await tester.pumpAndSettle();
    expect(store.selectedChannelId, isNull);
    expect(eventSubService.lastSwitchBroadcasterId, isNull);

    /// The unchecked row still adds.
    await tester.tap(find.text('Channel s-2'));
    await tester.pumpAndSettle();
    expect(store.channels.map((channel) => channel.id), contains('s-2'));

    await closeHiveInZone(tester);
  });

  testWidgets(
      'the moderated section fails independently — inline error and retry',
      (tester) async {
    channelService.moderatedThrows = Exception('boom');
    channelService.followedChannels = [ref('fol-1')];

    await pumpSheet(tester);

    expect(find.text('Channels you moderate'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Channel mod-1'), findsNothing);

    /// The followed section is unaffected.
    expect(find.text('Channel fol-1'), findsOneWidget);

    channelService.moderatedThrows = null;
    channelService.moderatedChannels = [ref('mod-1')];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(channelService.moderatedCalls, 2);
    expect(find.text('Channel mod-1'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets(
      'sections hidden when the token lacks the scope — re-login CTA shown',
      (tester) async {
    try {
      /// Downgrade the persisted token: no user:read:follows scope.
      final authBox = Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);
      final current = authBox.get(TwitchAuth.kBoxKey)!;
      await tester.runAsync(
        () => authBox.put(
          TwitchAuth.kBoxKey,
          TwitchAuth(
            accessToken: current.accessToken,
            refreshToken: current.refreshToken,
            expiresAtMs: current.expiresAtMs,
            scopes: const [
              'user:read:chat',
              'moderator:read:moderated_channels',
            ],
            userId: current.userId,
            userLogin: current.userLogin,
            userDisplayName: current.userDisplayName,
          ),
        ),
      );

      await pumpSheet(tester);

      expect(find.text('Channels you moderate'), findsOneWidget);
      expect(channelService.moderatedCalls, 1);
      expect(find.text('Channels you follow'), findsNothing);
      expect(channelService.followedCalls, 0);
      expect(find.text('Re-login'), findsOneWidget);
    } finally {
      await closeHiveInZone(tester);
    }
  });
}
