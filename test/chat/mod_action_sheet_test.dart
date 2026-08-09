import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/mod_action_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

ChatMessageEvent chatMessage(String id, String chatterId) => ChatMessageEvent(
      broadcasterUserId: 'user-1',
      chatterUserId: chatterId,
      chatterUserLogin: 'user$chatterId',
      chatterUserName: 'User$chatterId',
      messageId: id,
      message: ChatMessageText(
        text: 'text $id',
        fragments: [ChatMessageFragment(type: 'text', text: 'text $id')],
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchModerationService moderationService;
  late TwitchChatStore store;

  /// Pumps the real entry point behind a button so the sheet runs as a
  /// route (its close-on-action is exercised too).
  Future<void> openSheet(WidgetTester tester, ChatMessageEvent event) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModActionSheet(context, event),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mod_action_sheet_test');
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
    ];
    eventSubService = FakeTwitchEventSubService();
    moderationService = FakeTwitchModerationService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          eventSubService,
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      moderationService: moderationService,
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

  testWidgets('delete hits the service, tombstones and closes the sheet',
      (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);

    await openSheet(tester, event);

    expect(find.text('Moderate Useru1'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);
    expect(find.text('Timeout…'), findsOneWidget);
    expect(find.text('Ban'), findsOneWidget);

    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();

    expect(moderationService.deleteCalls, 1);
    expect(moderationService.lastDeleteMessageId, 'm1');
    expect(moderationService.lastDeleteBroadcasterId, 'user-1');
    expect(moderationService.lastDeleteModeratorId, 'user-1');
    expect(store.isMessageDeleted('m1'), isTrue);
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('Timeout… reveals presets; a preset times out with exact '
      'seconds', (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);

    await openSheet(tester, event);
    await tester.tap(find.text('Timeout…'));
    await tester.pumpAndSettle();

    expect(find.text('10 minutes'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
    expect(find.text('24 hours'), findsOneWidget);
    expect(moderationService.banCalls, 0);

    await tester.tap(find.text('10 minutes'));
    await tester.pumpAndSettle();

    expect(moderationService.banCalls, 1);
    expect(moderationService.lastBanUserId, 'u1');
    expect(moderationService.lastBanDurationSeconds, 600);
    expect(store.isMessageDeleted('m1'), isTrue);
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('Ban hits the service without a duration', (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);

    await openSheet(tester, event);
    await tester.tap(find.text('Ban'));
    await tester.pumpAndSettle();

    expect(moderationService.banCalls, 1);
    expect(moderationService.lastBanUserId, 'u1');
    expect(moderationService.lastBanDurationSeconds, isNull);
    expect(store.isMessageDeleted('m1'), isTrue);
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('a failure closes the sheet, shows a snackbar and changes '
      'nothing', (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);
    moderationService.deleteThrows = Exception('boom');

    await openSheet(tester, event);
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();

    expect(moderationService.deleteCalls, 1);
    expect(store.isMessageDeleted('m1'), isFalse);
    expect(find.byType(ModActionSheet), findsNothing);
    expect(find.text('Could not delete the message'), findsOneWidget);

    /// Drain the snackbar's dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('tapping a live message in a moderated channel opens the '
      'sheet', (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('text m1'));
    await tester.pumpAndSettle();

    expect(find.text('Delete message'), findsOneWidget);
  });

  testWidgets('no sheet in a non-moderated channel or for tombstones',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    /// Selected channel the user does not moderate — tap is inert.
    store.selectedChannelId = 'chan-other';

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('text m1'));
    await tester.pumpAndSettle();
    expect(find.text('Delete message'), findsNothing);

    /// Back in a moderated channel but tombstoned — the tap keeps its
    /// actor-reveal meaning instead of opening the sheet.
    store.selectedChannelId = null;
    store.applyModerationDelete('m1', 'Cool_Mod');
    await tester.pump();

    await tester.tap(find.textContaining('text m1'));
    await tester.pumpAndSettle();
    expect(find.text('Delete message'), findsNothing);
    expect(
      find.text("Cool_Mod deleted Useru1's message"),
      findsOneWidget,
    );
  });
}
