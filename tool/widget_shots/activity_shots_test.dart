import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/stores/views/activity.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/activity/activity_persistence.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/chat/chat_view.dart';
import 'package:obs_blade/views/chat/widgets/activity/activity_entry_points.dart';
import 'package:obs_blade/views/chat/widgets/activity/activity_feed.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
import 'package:obs_blade/models/enums/chat_type.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_twitch_services.dart'
    show FakeThirdPartyEmoteService;
import '../../test/pro/support/fake_pro_purchase_gateway.dart';
import 'support/shots_harness.dart';

class _NoRelay extends KickEventsRelayClient {
  @override
  Future<void> stop() async {}
}

/// Activity feed states: the feed (Pro / upsell / empty / to-thank /
/// narrow), the Chat tab segment + tablet side by side, the person and
/// options sheets, the chat header bell and the streaming-mode chip.
void main() {
  final harness = ShotsHarness();
  late ActivityStore store;
  late ProStore proStore;
  final now = DateTime.now().toUtc();

  /// The store's clock - shots that need coverage history step it
  DateTime? clockNow;

  setUpAll(ShotsHarness.loadFonts);

  Future<void> setPro(bool pro) async {
    final box = Hive.box(HiveKeys.Settings.name);
    await box.put(SettingsKeys.BoughtPro.name, pro);
    await box.put(SettingsKeys.ProColdStartRestoreDone.name, true);
  }

  setUp(() async {
    await harness.setUp();
    await setPro(true);
    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);
    store = ActivityStore(
      persistence: MemoryActivityPersistence(),
      isProResolver: () => true,
      clock: () => clockNow ?? DateTime.now(),
      relayClient: _NoRelay(),
      relayEnabledResolver: () => true,
      attachPlatformStores: false,
    );
    GetIt.instance.registerSingleton<ActivityStore>(store);
  });

  tearDown(() async {
    await store.dispose();
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  ActivityEvent event(
    String id,
    ActivityKind kind, {
    ActivityPlatform platform = ActivityPlatform.twitch,
    String actor = 'Fan',
    ActivityAmount? amount,
    String? tier,
    String? message,
    String? title,
    List<String> recipients = const [],
    required Duration ago,
    bool anonymous = false,
  }) => ActivityEvent(
    id: id,
    platform: platform,
    channelId: platform.name,
    kind: kind,
    actor: anonymous
        ? ActivityActor.anonymousActor
        : ActivityActor(id: actor, login: actor.toLowerCase(), name: actor),
    amount: amount,
    tier: tier,
    message: message,
    title: title,
    recipients: recipients,
    timestamp: now.subtract(ago),
    sources: {ActivitySource.native: id},
    primarySource: ActivitySource.native,
  );

  /// A live session with a mix of platforms, an earlier stream yesterday,
  /// and a few rows already seen (divider)
  Future<void> fill() async {
    await store.init();

    /// Yesterday's stream (ended) and its rows
    store.ingest(
      event(
        'y1',
        ActivityKind.giftSub,
        actor: 'GenerousGifter',
        amount: const ActivityAmount(10, ActivityUnit.subs),
        tier: '1000',
        ago: const Duration(hours: 26),
      ),
    );
    store.ingest(
      event(
        'y2',
        ActivityKind.follow,
        actor: 'NewFriend',
        ago: const Duration(hours: 26, minutes: 5),
      ),
    );
    store.ingest(
      event(
        'old1',
        ActivityKind.cheer,
        actor: 'BitsBaron',
        amount: const ActivityAmount(1000, ActivityUnit.bits),
        message: 'Cheer1000 for the clutch',
        ago: const Duration(minutes: 50),
      ),
    );
    store.ingest(
      event(
        'old2',
        ActivityKind.raid,
        actor: 'FriendlyStreamer',
        amount: const ActivityAmount(321, ActivityUnit.viewers),
        ago: const Duration(minutes: 45),
      ),
    );
    store.markAllSeen();
    store.ingest(
      event(
        'n1',
        ActivityKind.kicks,
        platform: ActivityPlatform.kick,
        actor: 'KickRegular',
        amount: const ActivityAmount(500, ActivityUnit.kicks),
        title: 'Rage Quit',
        message: 'w stream',
        ago: const Duration(minutes: 1),
      ),
    );
    store.ingest(
      event(
        'n2',
        ActivityKind.superChat,
        platform: ActivityPlatform.youtube,
        actor: 'Very Long YouTube Display Name That Wraps',
        amount: const ActivityAmount(25, 'USD', display: r'$25.00'),
        message:
            'Been watching since the first stream, this setup looks amazing - keep it up!',
        ago: const Duration(minutes: 3),
      ),
    );
    store.ingest(
      event(
        'n3',
        ActivityKind.resub,
        actor: 'LoyalViewer',
        amount: const ActivityAmount(14, ActivityUnit.months),
        tier: 'prime',
        ago: const Duration(minutes: 6),
      ),
    );
    store.ingest(
      event(
        'n4',
        ActivityKind.redemption,
        actor: 'PointsHoarder',
        title: 'Song request',
        amount: const ActivityAmount(500, ActivityUnit.points),
        message: 'play the intro song again',
        ago: const Duration(minutes: 8),
      ),
    );
    store.ingest(
      event(
        'n5',
        ActivityKind.follow,
        platform: ActivityPlatform.kick,
        actor: 'kickfan',
        ago: const Duration(minutes: 9),
      ),
    );
    store.ingest(
      event(
        'n6',
        ActivityKind.giftSub,
        anonymous: true,
        amount: const ActivityAmount(5, ActivityUnit.subs),
        tier: '1000',
        recipients: const ['a1', 'b2', 'c3', 'd4', 'e5'],
        ago: const Duration(minutes: 12),
      ),
    );
    store.setThanked(store.allEvents.firstWhere((e) => e.id == 'n3'), true);

    /// Live since an hour ago (rows from today fall in it), listened to
    /// all along
    clockNow = now.subtract(const Duration(hours: 1));
    store.setLiveForTest('twitch', true, since: clockNow);
    store.setNativeCoverageForTest(ActivityPlatform.twitch, 'twitch');

    /// The app ran all along: a tick every 30 s (a jump reads as a freeze)
    while (clockNow!.isBefore(now)) {
      clockNow = clockNow!.add(const Duration(seconds: 30));
      store.tickForTest();
    }
    clockNow = null;
  }

  /// [fill], but the phone was locked from 30 to 18 minutes ago
  Future<void> fillWithGap() async {
    await store.init();
    clockNow = now.subtract(const Duration(hours: 1));
    store.setLiveForTest('twitch', true, since: clockNow);
    store.setNativeCoverageForTest(ActivityPlatform.twitch, 'twitch');
    void runTo(Duration ago) {
      final target = now.subtract(ago);
      while (clockNow!.isBefore(target)) {
        clockNow = clockNow!.add(const Duration(seconds: 30));
        store.tickForTest();
      }
    }

    runTo(const Duration(minutes: 30));

    /// Suspended: no ticks, then the socket comes back
    clockNow = now.subtract(const Duration(minutes: 18));
    store.tickForTest();
    runTo(Duration.zero);
    clockNow = null;
    for (final (id, kind, actor, ago) in [
      ('g1', ActivityKind.sub, 'BeforeTheLock', 35),
      ('g2', ActivityKind.resub, 'AfterTheLock', 10),
      ('g3', ActivityKind.follow, 'Newcomer', 5),
    ]) {
      store.ingest(
        event(
          id,
          kind,
          actor: actor,
          ago: Duration(minutes: ago),
        ),
      );
    }
  }

  Widget framed(Widget child) =>
      Padding(padding: const EdgeInsets.all(12.0), child: child);

  testWidgets('feed', (tester) async {
    await tester.runAsync(fill);
    await harness.shot(tester, 'activity_feed', framed(const ActivityFeed()));
  });

  testWidgets('feed narrow', (tester) async {
    await tester.runAsync(fill);
    await harness.shot(
      tester,
      'activity_feed_narrow',
      framed(const ActivityFeed()),
      size: const Size(320, 640),
    );
  });

  testWidgets('to thank', (tester) async {
    await tester.runAsync(fill);
    store.setToThankOnly(true);
    await harness.shot(
      tester,
      'activity_feed_to_thank',
      framed(const ActivityFeed()),
    );
  });

  testWidgets('money filter', (tester) async {
    await tester.runAsync(fill);
    store.setFilter(ActivityFilter.money);
    await harness.shot(
      tester,
      'activity_feed_money',
      framed(const ActivityFeed()),
    );
  });

  testWidgets('empty', (tester) async {
    await tester.runAsync(store.init);
    await harness.shot(
      tester,
      'activity_feed_empty',
      framed(const ActivityFeed()),
    );
  });

  testWidgets('upsell', (tester) async {
    await tester.runAsync(() => setPro(false));
    await tester.runAsync(store.init);
    await harness.shot(
      tester,
      'activity_feed_upsell',
      framed(const ActivityFeed()),
    );
  });

  testWidgets('chat tab: activity segment', (tester) async {
    await tester.runAsync(fill);
    await tester.runAsync(
      () => Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ActivityChatTabSegment.name, kChatTabSegmentActivity),
    );
    await harness.shot(tester, 'activity_chat_tab_activity', const ChatView());
  });

  testWidgets('chat tab: chat segment with badge', (tester) async {
    await tester.runAsync(fill);
    await harness.shot(tester, 'activity_chat_tab_chat', const ChatView());
  });

  testWidgets('chat tab: tablet side by side', (tester) async {
    await tester.runAsync(fill);
    await harness.shot(
      tester,
      'activity_chat_tab_tablet',
      const ChatView(),
      size: kShotTablet,
    );
  });

  testWidgets('person sheet', (tester) async {
    await tester.runAsync(fill);
    store.ingest(
      event(
        'n7',
        ActivityKind.cheer,
        platform: ActivityPlatform.kick,
        actor: 'KickRegular',
        amount: const ActivityAmount(100, ActivityUnit.kicks),
        ago: const Duration(minutes: 20),
      ),
    );
    await harness.shot(
      tester,
      'activity_person_sheet_base',
      framed(const ActivityFeed()),
    );
    await tester.tap(
      find.textContaining('KickRegular', findRichText: true).first,
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/widget_shots/activity_person_sheet.png'),
    );
  });

  testWidgets('options sheet', (tester) async {
    await tester.runAsync(fill);
    await harness.shot(
      tester,
      'activity_options_sheet_base',
      framed(const ActivityFeed()),
    );
    await tester.tap(find.byKey(const Key('activity-options')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/widget_shots/activity_options_sheet.png'),
    );
  });

  testWidgets('options sheet: Kick relay missing some events', (tester) async {
    await tester.runAsync(fill);
    GetIt.instance.registerLazySingleton<KickChatStore>(
      () => KickChatStore(
        channelService: FakeKickChannelService(),
        authService: FakeKickAuthService(),
        apiService: FakeKickApiService(),
        pusherFactory: ({required onEvent, required onStateChanged}) =>
            FakeKickPusherService(
              onEvent: onEvent,
              onStateChanged: onStateChanged,
            ),
        isProResolver: () => true,
        emoteStoreResolver: () =>
            ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
        kickEmoteStoreResolver: () =>
            KickEmoteStore(service: FakeKickEmoteService()),
      ),
    );
    final kick = GetIt.instance<KickChatStore>();
    runInAction(() {
      kick.ownChannelSlug = 'kicker';
      store.relayState = KickRelayState.synced;
      store.relaySubscribed = false;
    });
    await harness.shot(
      tester,
      'activity_options_relay_partial_base',
      framed(const ActivityFeed()),
    );
    await tester.tap(find.byKey(const Key('activity-options')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('activity-kick-relay-state')), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/activity_options_relay_partial.png',
      ),
    );
  });

  testWidgets('chat header bell + streaming chip', (tester) async {
    await tester.runAsync(fill);
    await harness.shot(
      tester,
      'activity_header_and_chip',
      Column(
        children: [
          SizedBox(
            height: 220,
            child: framed(
              NativeChatWindow(
                chatType: ChatType.Twitch,
                status: NativeChatConnectionStatus.live,
                channelIsLive: true,
                channelViewerCount: 1234,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(12.0),
            color: Colors.blueGrey.shade800,
            child: const Stack(
              children: [
                Positioned(left: 8, bottom: 8, child: ActivityNewChip()),
              ],
            ),
          ),
        ],
      ),
    );
  });

  group('status banner', () {
    testWidgets('calm: tucked button only', (tester) async {
      await tester.runAsync(fill);
      await harness.shot(
        tester,
        'activity_status_tucked',
        framed(const ActivityFeed()),
      );
    });

    testWidgets('live on YouTube without setup: pops out', (tester) async {
      await tester.runAsync(fill);
      store.setObsLiveForTest(true, platform: ActivityPlatform.youtube);
      await harness.shot(
        tester,
        'activity_status_popped',
        framed(const ActivityFeed()),
      );
    });

    testWidgets('popped, narrow phone', (tester) async {
      await tester.runAsync(fill);
      store.setObsLiveForTest(true, platform: ActivityPlatform.youtube);
      await harness.shot(
        tester,
        'activity_status_popped_narrow',
        framed(const ActivityFeed()),
        size: const Size(320, 640),
      );
    });

    testWidgets('expanded: setup, gap, Kick reconnecting', (tester) async {
      await tester.runAsync(fillWithGap);
      GetIt.instance.registerLazySingleton<KickChatStore>(
        () => KickChatStore(
          channelService: FakeKickChannelService(),
          authService: FakeKickAuthService(),
          apiService: FakeKickApiService(),
          pusherFactory: ({required onEvent, required onStateChanged}) =>
              FakeKickPusherService(
                onEvent: onEvent,
                onStateChanged: onStateChanged,
              ),
          isProResolver: () => true,
          emoteStoreResolver: () =>
              ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
          kickEmoteStoreResolver: () =>
              KickEmoteStore(service: FakeKickEmoteService()),
        ),
      );
      final kick = GetIt.instance<KickChatStore>();
      runInAction(() {
        kick.ownChannelSlug = 'kicker';
        store.relayState = KickRelayState.retrying;
      });
      store.setObsLiveForTest(true, platform: ActivityPlatform.youtube);
      await harness.shot(
        tester,
        'activity_status_expanded_base',
        framed(const ActivityFeed()),
      );
      await tester.tap(find.byKey(const Key('activity-status-collapsed')));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../../build/widget_shots/activity_status_expanded.png',
        ),
      );
    });

    testWidgets('gap: badge, marker in the list, mark thanked', (tester) async {
      await tester.runAsync(fillWithGap);
      await harness.shot(
        tester,
        'activity_status_gap',
        framed(const ActivityFeed()),
      );
    });

    testWidgets('tablet side by side with the banner out', (tester) async {
      await tester.runAsync(fillWithGap);
      store.setObsLiveForTest(true, platform: ActivityPlatform.twitch);
      store.setObsLiveForTest(true, platform: ActivityPlatform.youtube);
      await harness.shot(
        tester,
        'activity_status_tablet',
        const ChatView(),
        size: kShotTablet,
      );
    });
  });
}
