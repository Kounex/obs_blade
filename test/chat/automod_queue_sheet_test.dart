import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/automod_events.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/automod_queue_sheet.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

AutoModMessageHoldEvent heldMessage(
  String messageId, {
  String userId = 'u-1',
  String userName = 'ShadyUser',
  String text = 'you are ugly',
  String reason = 'automod',
  AutoModClassification? automod =
      const AutoModClassification(category: 'aggressive', level: 3),
}) =>
    AutoModMessageHoldEvent(
      messageId: messageId,
      userId: userId,
      userLogin: userName.toLowerCase(),
      userName: userName,
      message: AutoModMessageContent(text: text),
      reason: reason,
      automod: automod,
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchModerationService moderationService;
  late TwitchChatStore store;

  /// Bounded pumps, not pumpAndSettle — same sheet-route idiom as the
  /// bans sheet tests.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showAutoModQueueSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('automod_queue_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    authService.tokenScopes = const [
      'user:read:chat',
      'user:write:chat',
      'moderator:manage:chat_messages',
      'moderator:manage:banned_users',
      'moderator:manage:automod',
    ];
    eventSubService = FakeTwitchEventSubService();
    moderationService = FakeTwitchModerationService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________,
              _________, __________) =>
          eventSubService,
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      moderationService: moderationService,
      channelService: FakeTwitchChannelService(),
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
    );
    await store.startLogin();
    store.chatConnection = TwitchChatConnectionState.live;
    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()));
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders the held messages with meta line and pills',
      (tester) async {
    store.applyAutoModMessageHold(heldMessage('am-1'));
    store.applyAutoModMessageHold(heldMessage(
      'am-2',
      userName: 'TermBot',
      text: 'blocked phrase',
      reason: 'blocked_term',
      automod: null,
    ));

    await openSheet(tester);

    expect(find.text('AutoMod queue'), findsOneWidget);
    expect(find.text('ShadyUser'), findsOneWidget);
    expect(find.text('you are ugly'), findsOneWidget);
    expect(
      find.textContaining('AutoMod · aggressive · level 3'),
      findsOneWidget,
    );
    expect(find.text('TermBot'), findsOneWidget);
    expect(find.textContaining('Blocked term'), findsOneWidget);
    expect(find.text('Allow'), findsNWidgets(2));
    expect(find.text('Deny'), findsNWidgets(2));
  });

  testWidgets('empty queue shows the empty label', (tester) async {
    await openSheet(tester);

    expect(find.text('No held messages'), findsOneWidget);
  });

  testWidgets('Allow confirms, then resolves and drops the row',
      (tester) async {
    store.applyAutoModMessageHold(heldMessage('am-1'));
    await openSheet(tester);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(find.text('Allow this message?'), findsOneWidget);
    expect(moderationService.autoModCalls, 0);

    await tester.tap(find.text('Allow').last);
    await tester.pumpAndSettle();

    expect(moderationService.autoModCalls, 1);
    expect(moderationService.lastAutoModMessageId, 'am-1');
    expect(moderationService.lastAutoModAllow, isTrue);
    expect(find.text('you are ugly'), findsNothing);
    expect(find.text('No held messages'), findsOneWidget);
  });

  testWidgets('Deny confirms with deny and drops the row', (tester) async {
    store.applyAutoModMessageHold(heldMessage('am-1'));
    await openSheet(tester);

    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();

    expect(find.text('Deny this message?'), findsOneWidget);

    await tester.tap(find.text('Deny').last);
    await tester.pumpAndSettle();

    expect(moderationService.autoModCalls, 1);
    expect(moderationService.lastAutoModAllow, isFalse);
    expect(find.text('No held messages'), findsOneWidget);
  });

  testWidgets('a failed resolve keeps the row and shows a snackbar',
      (tester) async {
    moderationService.autoModThrows = Exception('boom');
    store.applyAutoModMessageHold(heldMessage('am-1'));
    await openSheet(tester);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow').last);
    await tester.pumpAndSettle();

    expect(moderationService.autoModCalls, 1);
    expect(find.text('you are ugly'), findsOneWidget);
    expect(find.text('Could not resolve the message'), findsOneWidget);

    /// Drain the snackbar's dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('a new hold appears live; a resolution echo drops the row',
      (tester) async {
    await openSheet(tester);
    expect(find.text('No held messages'), findsOneWidget);

    store.applyAutoModMessageHold(heldMessage('am-1'));
    await settle(tester);

    expect(find.text('ShadyUser'), findsOneWidget);

    store.applyAutoModMessageUpdate(
      const AutoModMessageUpdateEvent(messageId: 'am-1', status: 'approved'),
    );
    await settle(tester);

    expect(find.text('ShadyUser'), findsNothing);
    expect(find.text('No held messages'), findsOneWidget);
  });
}
