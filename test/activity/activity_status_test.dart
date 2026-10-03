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
import 'package:obs_blade/utils/activity/activity_ledger.dart';
import 'package:obs_blade/utils/activity/activity_persistence.dart';
import 'package:obs_blade/utils/activity/activity_status.dart';
import 'package:obs_blade/utils/activity/youtube_own_activity_poller.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/chat/widgets/activity/activity_feed.dart';

import '../persistence/support/hive_test_harness.dart';
import '../pro/support/fake_pro_purchase_gateway.dart';

class _NoRelay extends KickEventsRelayClient {
  @override
  Future<void> stop() async {}
}

List<ActivityStatusItem> _build(ActivityStatusInput input) =>
    buildActivityStatus(input, time: (at) => '${at.hour}:${at.minute}');

List<String> _ids(ActivityStatusInput input) =>
    _build(input).map((item) => item.id).toList();

ActivityStatusItem _item(ActivityStatusInput input, String id) =>
    _build(input).firstWhere((item) => item.id == id);

void main() {
  group('status lines', () {
    test('nothing set up and not live: nothing to say', () {
      expect(_ids(const ActivityStatusInput()), isEmpty);
    });

    group('YouTube', () {
      test('live on YouTube without an API key: set up (action)', () {
        final item = _item(
          const ActivityStatusInput(
            obsLive: true,
            obsLivePlatform: ActivityPlatform.youtube,
          ),
          'youtube-setup',
        );
        expect(item.level, ActivityStatusLevel.action);
        expect(item.action, ActivityStatusAction.youTubeSetUp);
      });

      test('API key only: sign in (info), action while live on YouTube', () {
        final calm = _item(
          const ActivityStatusInput(
            youTubeConfigured: true,
            youTubeCanSignIn: true,
          ),
          'youtube-signin',
        );
        expect(calm.level, ActivityStatusLevel.info);
        expect(calm.action, ActivityStatusAction.youTubeSignIn);
        expect(calm.text, contains('can\'t tell which channel is yours'));

        final live = _item(
          const ActivityStatusInput(
            youTubeConfigured: true,
            youTubeCanSignIn: true,
            obsLive: true,
            obsLivePlatform: ActivityPlatform.youtube,
          ),
          'youtube-signin',
        );
        expect(live.level, ActivityStatusLevel.action);
        expect(live.text, startsWith('You\'re live on YouTube'));
      });

      test('API key only, no OAuth client: the button sets up sign-in', () {
        final item = _item(
          const ActivityStatusInput(youTubeConfigured: true),
          'youtube-signin',
        );
        expect(item.action, ActivityStatusAction.youTubeSetUp);
        expect(item.actionLabel, 'Set up sign-in');
      });

      test('signed in without a channel: switch account', () {
        expect(
          _item(
            const ActivityStatusInput(
              youTubeConfigured: true,
              youTubeSignedIn: true,
              youTubeNoChannel: true,
            ),
            'youtube-nochannel',
          ).action,
          ActivityStatusAction.youTubeSwitchAccount,
        );

        /// Not known to be channel-less (lookup pending): no wrong advice
        expect(
          _ids(
            const ActivityStatusInput(
              youTubeConfigured: true,
              youTubeSignedIn: true,
            ),
          ),
          ['youtube-nochannel-yet'],
        );
      });

      test('own channel: waiting / listening / quota', () {
        const base = ActivityStatusInput(
          youTubeConfigured: true,
          youTubeSignedIn: true,
          youTubeChannelId: 'UCme',
          youTubeOwn: YouTubeOwnActivityState.waiting,
        );
        expect(_ids(base), ['youtube-waiting']);
        expect(
          _ids(
            const ActivityStatusInput(
              youTubeConfigured: true,
              youTubeSignedIn: true,
              youTubeChannelId: 'UCme',
              youTubeOwn: YouTubeOwnActivityState.standby,
            ),
          ),
          ['youtube-ok'],
        );
        final quota = _item(
          ActivityStatusInput(
            youTubeConfigured: true,
            youTubeSignedIn: true,
            youTubeChannelId: 'UCme',
            youTubeOwn: YouTubeOwnActivityState.quotaExhausted,
            youTubeQuotaResetAt: DateTime(2026, 10, 3, 9, 1),
          ),
          'youtube-quota',
        );
        expect(quota.level, ActivityStatusLevel.warning);
        expect(quota.text, contains('9:1'));
      });
    });

    group('Twitch', () {
      test('signed out: only while live on Twitch', () {
        expect(_ids(const ActivityStatusInput(obsLive: true)), isEmpty);
        expect(
          _item(
            const ActivityStatusInput(
              obsLive: true,
              obsLivePlatform: ActivityPlatform.twitch,
            ),
            'twitch-signin',
          ).level,
          ActivityStatusLevel.action,
        );
      });

      test('old token, failed / connecting / listening', () {
        expect(
          _ids(
            const ActivityStatusInput(
              twitchSignedIn: true,
              twitchMissingScopes: true,
              twitchConnection: ActivityTwitchConnection.connected,
            ),
          ),
          ['twitch-scopes', 'twitch-ok'],
        );
        expect(
          _item(
            const ActivityStatusInput(
              twitchSignedIn: true,
              twitchConnection: ActivityTwitchConnection.failed,
            ),
            'twitch-failed',
          ).action,
          ActivityStatusAction.twitchRetry,
        );
        expect(
          _item(
            const ActivityStatusInput(twitchSignedIn: true),
            'twitch-connecting',
          ).level,
          ActivityStatusLevel.info,
        );
      });
    });

    group('Kick', () {
      test('not signed in: only for someone who reads Kick', () {
        expect(_ids(const ActivityStatusInput()), isEmpty);
        expect(_ids(const ActivityStatusInput(kickUsed: true)), [
          'kick-signin',
        ]);
      });

      test('relay off / reconnecting / partial / listening', () {
        expect(
          _item(
            const ActivityStatusInput(
              kickSignedIn: true,
              kickRelayEnabled: false,
            ),
            'kick-relay-off',
          ).action,
          ActivityStatusAction.kickRelayOn,
        );
        expect(
          _item(
            const ActivityStatusInput(
              kickSignedIn: true,
              kickRelay: KickRelayState.retrying,
            ),
            'kick-retrying',
          ).level,
          ActivityStatusLevel.warning,
        );
        expect(
          _ids(
            const ActivityStatusInput(
              kickSignedIn: true,
              kickRelay: KickRelayState.synced,
              kickRelaySubscribed: false,
            ),
          ),
          ['kick-partial'],
        );
        expect(
          _ids(
            const ActivityStatusInput(
              kickSignedIn: true,
              kickRelay: KickRelayState.synced,
            ),
          ),
          ['kick-ok'],
        );
      });
    });

    test('gaps: warnings, newest first, a running one says "since"', () {
      final items = _build(
        ActivityStatusInput(
          gaps: [
            ActivityGap(
              platform: ActivityPlatform.twitch,
              start: DateTime(2026, 10, 2, 21, 4),
              end: DateTime(2026, 10, 2, 21, 19),
            ),
            ActivityGap(
              platform: ActivityPlatform.youtube,
              start: DateTime(2026, 10, 2, 22, 30),
            ),
          ],
        ),
      );
      expect(items.map((item) => item.level).toSet(), {
        ActivityStatusLevel.warning,
      });
      expect(items.first.text, startsWith('YouTube: not listening since'));
      expect(items.last.text, contains('21:4–21:19'));
      expect(items.last.text, contains('follows were filled in'));
    });

    test('most pressing first', () {
      final items = _build(
        const ActivityStatusInput(
          twitchSignedIn: true,
          twitchConnection: ActivityTwitchConnection.connected,
          kickSignedIn: true,
          kickRelay: KickRelayState.retrying,
          youTubeConfigured: true,
        ),
      );
      expect(items.map((item) => item.level).toList(), [
        ActivityStatusLevel.warning,
        ActivityStatusLevel.info,
        ActivityStatusLevel.ok,
      ]);
    });
  });

  group('banner', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late ProStore proStore;
    late ActivityStore store;
    late MemoryActivityPersistence persistence;
    late DateTime now;

    Box<dynamic> settings() => Hive.box(HiveKeys.Settings.name);

    ActivityStore build() => ActivityStore(
      persistence: persistence,
      isProResolver: () => true,
      clock: () => now,
      relayClient: _NoRelay(),
      relayEnabledResolver: () => true,
      attachPlatformStores: false,
    );

    setUp(() async {
      now = DateTime.utc(2026, 10, 2, 20);
      tempDir = await Directory.systemTemp.createTemp('activity_status');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
      await settings().put(SettingsKeys.BoughtPro.name, true);
      await settings().put(SettingsKeys.ProColdStartRestoreDone.name, true);
      proStore = ProStore(
        service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
      )..init();
      GetIt.instance.registerSingleton<ProStore>(proStore);
      persistence = MemoryActivityPersistence();
      store = build();
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

    Widget wrap() => MaterialApp(
      theme: ThemeData(
        cupertinoOverrideTheme: const CupertinoThemeData(),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        extensions: const [AppStatusColors.standard, AppTextColors.standard],
      ),
      home: const Scaffold(body: ActivityFeed()),
    );

    final tucked = find.byKey(const Key('activity-status-tucked'));
    final collapsed = find.byKey(const Key('activity-status-collapsed'));
    final expanded = find.byKey(const Key('activity-status-expanded'));
    final badge = find.byKey(const Key('activity-status-badge'));

    testWidgets('calm: tucked, no badge; opening shows the lines', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      expect(tucked, findsOneWidget);
      expect(badge, findsNothing);
      await tester.tap(tucked);
      await tester.pumpAndSettle();
      expect(expanded, findsOneWidget);
      expect(find.text('Feed status'), findsOneWidget);
    });

    testWidgets('live on YouTube without setup: it comes out by itself, '
        'expands to the fix, ✕ puts it away for good', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      store.setObsLiveForTest(true, platform: ActivityPlatform.youtube);
      await tester.pumpAndSettle();
      expect(collapsed, findsOneWidget);
      expect(find.textContaining('You\'re live on YouTube'), findsOneWidget);

      await tester.tap(collapsed);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('activity-status-action-youtube-setup')),
        findsOneWidget,
      );
      expect(store.acknowledgedStatus, contains('youtube-setup'));

      await tester.tap(find.byKey(const Key('activity-status-close')).first);
      await tester.pumpAndSettle();
      expect(tucked, findsOneWidget);
      expect(badge, findsNothing);

      /// Rebuilt (another feed / tab): seen stays seen
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      expect(tucked, findsOneWidget);
    });

    testWidgets('a gap badges the tucked button without popping out; '
        'opening clears the badge', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      store.setLiveForTest('twitch', true);
      store.setNativeCoverageForTest(ActivityPlatform.twitch, '1');
      now = now.add(const Duration(seconds: 20));
      store.setNativeCoverageForTest(ActivityPlatform.twitch, null);
      for (var i = 0; i < 6; i++) {
        now = now.add(const Duration(seconds: 30));
        store.tickForTest();
      }
      await tester.pumpAndSettle();
      expect(tucked, findsOneWidget);
      expect(collapsed, findsNothing);
      expect(badge, findsOneWidget);

      await tester.tap(tucked);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Twitch: not listening since'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('activity-status-close')).first);
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
    });

    test('acknowledged lines survive a restart', () async {
      store.acknowledgeStatus(['gap:twitch:x', 'youtube-setup']);
      await store.dispose();
      store = build();
      await store.init();
      expect(store.acknowledgedStatus, {'gap:twitch:x', 'youtube-setup'});
    });
  });
}
