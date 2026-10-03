import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/activity.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/activity/activity_persistence.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/chat/chat_view.dart';
import 'package:obs_blade/views/chat/widgets/activity/activity_entry_points.dart';
import 'package:obs_blade/views/chat/widgets/activity/activity_feed.dart';
import 'package:obs_blade/views/chat/widgets/activity/activity_formatting.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

class _NoRelay extends KickEventsRelayClient {
  @override
  Future<void> stop() async {}
}

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(
    cupertinoOverrideTheme: const CupertinoThemeData(),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
    extensions: const [AppStatusColors.standard, AppTextColors.standard],
  ),
  home: Scaffold(body: child),
);

ActivityEvent _event(
  String id,
  ActivityKind kind, {
  String actor = 'Fan',
  ActivityAmount? amount,
}) => ActivityEvent(
  id: id,
  platform: ActivityPlatform.twitch,
  channelId: '1',
  kind: kind,
  actor: ActivityActor(id: actor, name: actor),
  amount: amount,
  timestamp: DateTime.now().toUtc(),
  sources: {ActivitySource.native: id},
  primarySource: ActivitySource.native,
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late ProStore proStore;
  late ActivityStore store;

  Box<dynamic> settings() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('activity_ui');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await settings().put(SettingsKeys.BoughtPro.name, true);
    await settings().put(SettingsKeys.ProColdStartRestoreDone.name, true);
    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);
    store = ActivityStore(
      persistence: MemoryActivityPersistence(),
      isProResolver: () => true,
      relayClient: _NoRelay(),
      relayEnabledResolver: () => true,
      attachPlatformStores: false,
    );
    GetIt.instance.registerSingleton<ActivityStore>(store);
    await store.init();
  });

  tearDown(() async {
    await store.dispose();
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('swiping a row toggles thanked and keeps the row', (
    tester,
  ) async {
    store.ingest(_event('sub', ActivityKind.sub, actor: 'Subber'));
    await tester.pumpWidget(_wrap(const ActivityFeed()));
    await tester.pump();
    expect(store.toThankCount, 1);

    await tester.drag(
      find.textContaining('Subber', findRichText: true),
      const Offset(300, 0),
    );
    await tester.pumpAndSettle();
    expect(store.toThankCount, 0);
    expect(store.allEvents.single.thanked, isTrue);
    expect(find.textContaining('Subber', findRichText: true), findsOneWidget);
  });

  testWidgets('to-thank chip filters to unthanked big rows', (tester) async {
    store.ingest(_event('sub', ActivityKind.sub, actor: 'Subber'));
    store.ingest(_event('follow', ActivityKind.follow, actor: 'Follower'));
    await tester.pumpWidget(_wrap(const ActivityFeed()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('activity-to-thank')));
    await tester.pump();
    expect(find.textContaining('Follower', findRichText: true), findsNothing);
    expect(find.textContaining('Subber', findRichText: true), findsOneWidget);
  });

  testWidgets('leaving the feed marks what it showed as seen', (tester) async {
    store.ingest(_event('sub', ActivityKind.sub));
    expect(store.unseenCount, 1);
    await tester.pumpWidget(_wrap(const ActivityFeed()));
    await tester.pump();

    /// Still unseen while on screen (badge reads it), divider stays put
    expect(store.unseenCount, 1);
    await tester.pumpWidget(_wrap(const SizedBox.shrink()));
    expect(store.unseenCount, 0);
  });

  testWidgets('not Pro: upsell instead of the feed', (tester) async {
    await tester.runAsync(
      () => settings().put(SettingsKeys.BoughtPro.name, false),
    );
    await tester.pumpWidget(_wrap(const ActivityFeed()));
    await tester.pump();
    expect(find.text('Explore Pro'), findsOneWidget);
    expect(find.byKey(const Key('activity-to-thank')), findsNothing);
  });

  testWidgets('header bell: badge count, hidden when the feed is beside it', (
    tester,
  ) async {
    store.ingest(_event('a', ActivityKind.sub));
    store.ingest(_event('b', ActivityKind.follow, actor: 'Other'));
    await tester.pumpWidget(_wrap(const ChatActivityButton()));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        ActivityHostScope(
          show: () {},
          feedVisible: true,
          child: const ChatActivityButton(),
        ),
      ),
    );
    expect(find.byKey(const Key('chat-activity-button')), findsNothing);
  });

  testWidgets('header bell inside the Chat tab switches the segment', (
    tester,
  ) async {
    var shown = 0;
    await tester.pumpWidget(
      _wrap(
        ActivityHostScope(
          show: () => shown++,
          feedVisible: false,
          child: const ChatActivityButton(),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('chat-activity-button')));
    expect(shown, 1);
  });

  testWidgets('streaming chip only with something new', (tester) async {
    await tester.pumpWidget(_wrap(const ActivityNewChip()));
    await tester.pump();
    expect(find.byKey(const Key('activity-new-chip')), findsNothing);
    store.ingest(_event('a', ActivityKind.cheer));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 new'), findsOneWidget);
  });

  testWidgets('Chat tab: segment switch keeps the chat mounted and persists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    store.ingest(_event('a', ActivityKind.sub));
    await tester.pumpWidget(_wrap(const ChatView()));
    await tester.pump();
    expect(find.byKey(const Key('chat-tab-activity-badge')), findsOneWidget);

    /// The segment write is a Hive put - real async, or teardown hangs
    await tester.runAsync(() async {
      await tester.tap(find.text('Activity').first);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ActivityFeed), findsOneWidget);

    /// The chat is still in the tree (offstage), not rebuilt from scratch
    expect(find.text('Twitch Chat', skipOffstage: false), findsOneWidget);
    expect(
      settings().get(SettingsKeys.ActivityChatTabSegment.name),
      kChatTabSegmentActivity,
    );
  });

  testWidgets('Chat tab: back to the chat clears the badge cleanly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    store.ingest(_event('a', ActivityKind.sub));
    await tester.pumpWidget(_wrap(const ChatView()));
    await tester.pump();
    Future<void> tapSegment(String label) async {
      await tester.runAsync(() async {
        await tester.tap(find.text(label).first);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await tapSegment('Activity');
    expect(find.byKey(const Key('chat-tab-activity-badge')), findsOneWidget);

    /// The feed unmounts and marks its rows seen; the badge (still
    /// mounted) follows - flutter_mobx defers its rebuild past the frame
    await tapSegment('Chat');
    expect(tester.takeException(), isNull);
    expect(store.unseenCount, 0);
    expect(find.byKey(const Key('chat-tab-activity-badge')), findsNothing);
  });

  testWidgets('tablet split: no overflow in a narrow feed pane', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(744, 1133) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    for (var i = 0; i < 12; i++) {
      store.ingest(
        _event(
          'e$i',
          ActivityKind.giftSub,
          actor: 'AVeryLongDisplayNameForTesting$i',
          amount: const ActivityAmount(50, ActivityUnit.subs),
        ),
      );
    }
    await tester.pumpWidget(_wrap(const ChatView()));
    await tester.pump();
    expect(find.byType(ActivityFeed), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('formatting', () {
    test('actions read naturally', () {
      expect(
        activityActionText(
          _event(
            'g',
            ActivityKind.giftSub,
            amount: const ActivityAmount(5, ActivityUnit.subs),
          ),
        ),
        'gifted 5 subs',
      );
      expect(
        activityActionText(
          _event(
            'c',
            ActivityKind.cheer,
            amount: const ActivityAmount(1200, ActivityUnit.bits),
          ),
        ),
        'cheered 1,200 bits',
      );
      expect(
        formatActivityAmount(const ActivityAmount(25.5, 'USD')),
        r'$25.50',
      );
      expect(
        formatActivityAmount(const ActivityAmount(1, ActivityUnit.subs)),
        '1 sub',
      );
      expect(activityBadgeText(150), '99+');
    });

    test('totals keep currencies apart and money first', () {
      final text = formatActivityTotals(
        const ActivityTotals(
          amounts: {'USD': 10, 'EUR': 5, ActivityUnit.bits: 300},
          subs: 2,
          follows: 1,
        ),
      );
      expect(text, startsWith('€5.00 · \$10.00 · 300 bits'));
      expect(text, endsWith('2 subs · 1 follow'));
    });

    /// Meaningful under a DST zone (e.g. TZ=Europe/Berlin): 23 h between
    /// the two local midnights
    test('day labels count calendar days across a DST switch', () {
      final now = DateTime(2026, 3, 30, 10);
      String title(DateTime day) => activityGroupTitle(
        ActivityGroup(day: day, events: []),
        now: now,
      );
      expect(title(DateTime(2026, 3, 30)), 'Today');
      expect(title(DateTime(2026, 3, 29)), 'Yesterday');
      expect(title(DateTime(2026, 3, 28)), isNot('Yesterday'));
    });
  });
}
