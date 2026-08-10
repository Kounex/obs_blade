import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_reply_strip.dart';

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
  late TwitchChatStore store;

  Widget wrap() => const MaterialApp(
        home: Scaffold(body: NativeReplyStrip(accentColor: Colors.purple)),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reply_strip_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    final authService = FakeTwitchAuthService();
    authService.tokenScopes = const ['user:read:chat', 'user:write:chat'];
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          FakeTwitchEventSubService(),
      badgeStoreResolver: () =>
          TwitchBadgeStore(service: FakeTwitchBadgeService()),
      messageService: FakeTwitchMessageService(),
    );
    await store.startLogin();
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

  testWidgets('renders nothing without a reply target', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byIcon(CupertinoIcons.reply), findsNothing);
    expect(find.textContaining('Replying to'), findsNothing);
  });

  testWidgets('shows author and excerpt while a target is set; x cancels',
      (tester) async {
    store.setReplyTarget(chatMessage('parent-1', 'u7'));
    await tester.pumpWidget(wrap());

    expect(find.byIcon(CupertinoIcons.reply), findsOneWidget);
    expect(
      find.textContaining('Replying to @Useru7: text parent-1'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(CupertinoIcons.xmark));
    await tester.pump();

    expect(store.replyTarget, isNull);
    expect(find.textContaining('Replying to'), findsNothing);
  });

  testWidgets('setting a new target replaces the old one', (tester) async {
    store.setReplyTarget(chatMessage('parent-1', 'u7'));
    await tester.pumpWidget(wrap());
    expect(find.textContaining('@Useru7'), findsOneWidget);

    store.setReplyTarget(chatMessage('parent-2', 'u9'));
    await tester.pump();

    expect(find.textContaining('@Useru9: text parent-2'), findsOneWidget);
  });
}
