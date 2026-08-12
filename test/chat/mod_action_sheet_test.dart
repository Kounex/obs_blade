import 'dart:io';

import 'package:flutter/cupertino.dart';
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

    expect(find.text('Delete message?'), findsOneWidget);
    expect(moderationService.deleteCalls, 0);

    await tester.tap(find.text('Delete'));
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

    expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);
    expect(find.text('Back'), findsNothing);
    expect(find.text('1 minute'), findsOneWidget);
    expect(find.text('5 minutes'), findsOneWidget);
    expect(find.text('10 minutes'), findsOneWidget);
    expect(find.text('30 minutes'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
    expect(find.text('12 hours'), findsOneWidget);
    expect(find.text('24 hours'), findsOneWidget);
    expect(find.text('1 week'), findsOneWidget);
    expect(moderationService.banCalls, 0);

    await tester.tap(find.text('1 minute'));
    await tester.pumpAndSettle();

    expect(find.text('Timeout Useru1?'), findsOneWidget);
    expect(moderationService.banCalls, 0);

    await tester.tap(find.text('Timeout'));
    await tester.pumpAndSettle();

    expect(moderationService.banCalls, 1);
    expect(moderationService.lastBanUserId, 'u1');
    expect(moderationService.lastBanDurationSeconds, 60);
    expect(store.isMessageDeleted('m1'), isTrue);
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('Ban hits the service without a duration', (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);

    await openSheet(tester, event);
    await tester.tap(find.text('Ban').last);
    await tester.pumpAndSettle();

    expect(find.text('Ban Useru1?'), findsOneWidget);
    expect(moderationService.banCalls, 0);

    await tester.tap(find.text('Ban').last);
    await tester.pumpAndSettle();

    expect(moderationService.banCalls, 1);
    expect(moderationService.lastBanUserId, 'u1');
    expect(moderationService.lastBanDurationSeconds, isNull);
    expect(store.isMessageDeleted('m1'), isTrue);
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('canceling confirmation leaves the sheet open and does '
      'nothing', (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);

    await openSheet(tester, event);
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(moderationService.deleteCalls, 0);
    expect(store.isMessageDeleted('m1'), isFalse);
    expect(find.byType(ModActionSheet), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);
  });

  testWidgets('a failure closes the sheet, shows a snackbar and changes '
      'nothing', (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);
    moderationService.deleteThrows = Exception('boom');

    await openSheet(tester, event);
    await tester.tap(find.text('Delete message'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(moderationService.deleteCalls, 1);
    expect(store.isMessageDeleted('m1'), isFalse);
    expect(find.byType(ModActionSheet), findsNothing);
    expect(find.text('Could not delete the message'), findsOneWidget);

    /// Drain the snackbar's dismiss timer so no timer outlives the test.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('long-pressing a live message in a moderated channel opens '
      'the sheet', (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();

    expect(find.text('Delete message'), findsOneWidget);
  });

  testWidgets('mod sheet offers Reply; tapping it sets the reply target',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();

    /// Reply sits above the moderation actions.
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Delete message'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(store.replyTarget?.messageId, 'm1');
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('non-mod with write scope gets a reply-only sheet',
      (tester) async {
    store.appendChatMessageForTest(chatMessage('m1', 'u1'));

    /// Selected channel the user does not moderate.
    store.selectedChannelId = 'chan-other';

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();

    expect(find.text('Message from @Useru1'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Delete message'), findsNothing);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();

    expect(store.replyTarget?.messageId, 'm1');
    expect(find.byType(MessageActionSheet), findsNothing);
  });

  testWidgets('read-only non-mod gets no sheet; tombstones stay inert',
      (tester) async {
    /// Drop the write scope from the persisted auth — `canWriteChat` reads
    /// the box live, nothing actionable for a non-mod then. No save():
    /// the box serves this same in-memory instance on get(), and a Hive
    /// write (real I/O) would never complete inside testWidgets' fake
    /// async zone.
    final authBox = Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);
    final auth = authBox.get(TwitchAuth.kBoxKey)!;
    auth.scopes =
        auth.scopes.where((scope) => scope != 'user:write:chat').toList();

    store.appendChatMessageForTest(chatMessage('m1', 'u1'));
    store.selectedChannelId = 'chan-other';

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: NativeTwitchChatView())),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.textContaining('text m1'));
    await tester.pumpAndSettle();
    expect(find.text('Reply'), findsNothing);
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

  testWidgets('Pin message pins directly when nothing is pinned yet',
      (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);
    store.pinnedMessage = null;

    await openSheet(tester, event);

    expect(find.text('Pin message'), findsOneWidget);
    expect(find.text('Unpin message'), findsNothing);

    await tester.tap(find.text('Pin message'));
    await tester.pumpAndSettle();

    /// No confirmation when no pin gets replaced.
    expect(moderationService.pinCalls, 1);
    expect(moderationService.lastPinMessageId, 'm1');
    expect(store.pinnedMessage?.messageId, 'm1');
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('Pin message asks before replacing the active pin',
      (tester) async {
    final event = chatMessage('m1', 'u1');
    store.appendChatMessageForTest(event);

    /// Flush the login connect's pin fetch — the sample pin is active.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(store.pinnedMessage?.messageId, 'msg-pinned');

    await openSheet(tester, event);
    await tester.tap(find.text('Pin message'));
    await tester.pumpAndSettle();

    expect(find.text('Pin this message?'), findsOneWidget);
    expect(moderationService.pinCalls, 0);

    await tester.tap(find.text('Pin').last);
    await tester.pumpAndSettle();

    expect(moderationService.pinCalls, 1);
    expect(moderationService.lastPinMessageId, 'm1');
    expect(store.pinnedMessage?.messageId, 'm1');
    expect(find.byType(ModActionSheet), findsNothing);
  });

  testWidgets('the pinned message offers Unpin message and unpins directly',
      (tester) async {
    final event = chatMessage('msg-pinned', 'u1');
    store.appendChatMessageForTest(event);

    /// Flush the login connect's pin fetch — the sample pin is active.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(store.pinnedMessage?.messageId, 'msg-pinned');

    await openSheet(tester, event);

    expect(find.text('Unpin message'), findsOneWidget);
    expect(find.text('Pin message'), findsNothing);

    await tester.tap(find.text('Unpin message'));
    await tester.pumpAndSettle();

    /// No confirmation for unpin.
    expect(moderationService.unpinCalls, 1);
    expect(moderationService.lastUnpinMessageId, 'msg-pinned');
    expect(store.pinnedMessage, isNull);
    expect(find.byType(ModActionSheet), findsNothing);
  });
}
