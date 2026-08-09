import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/chat_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

ChatMessageEvent cardMessage(
  String id,
  String userId,
  String text, {
  DateTime? receivedAt,
}) =>
    ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: userId,
      chatterUserLogin: 'login-$userId',
      chatterUserName: 'Name$userId',
      messageId: id,
      color: '#9146FF',
      receivedAt: receivedAt,
      message: ChatMessageText(
        text: text,
        fragments: [ChatMessageFragment(type: 'text', text: text)],
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late FakeTwitchBadgeService badgeService;
  late FakeTwitchUserService userService;
  late TwitchChatStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_user_card_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);

    authService = FakeTwitchAuthService();
    eventSubService = FakeTwitchEventSubService();
    badgeService = FakeTwitchBadgeService();
    userService = FakeTwitchUserService();

    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          eventSubService,
      badgeStoreResolver: () => TwitchBadgeStore(service: badgeService),
    );
    store.authState = TwitchAuthState.loggedIn;
    store.user = const TwitchUser(
      id: 'self-1',
      login: 'selflogin',
      displayName: 'SelfUser',
    );

    GetIt.instance.registerSingleton<TwitchChatStore>(store);
    GetIt.instance.registerSingleton<TwitchBadgeStore>(
      TwitchBadgeStore(service: badgeService),
    );
    GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
      ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
    );

    await Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).put(
      TwitchAuth.kBoxKey,
      TwitchAuth(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
        scopes: const [
          'user:read:follows',
          'user:read:subscriptions',
          'moderator:read:followers',
        ],
        userId: 'self-1',
      ),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> openCard(
    WidgetTester tester, {
    required String userId,
    ChatUserCardConnection? connection,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showChatUserCardSheet(
                  context,
                  userId: userId,
                  connection: connection,
                  userService: userService,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('shows buffered messages from the store', (tester) async {
    store.appendChatMessageForTest(cardMessage('m2', 'viewer-1', 'second'));
    store.appendChatMessageForTest(cardMessage('m1', 'viewer-1', 'first'));

    userService.userResult = const TwitchUser(
      id: 'viewer-1',
      login: 'viewerlogin',
      displayName: 'ViewerOne',
    );

    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    expect(find.textContaining('Nameviewer-1: second'), findsOneWidget);
    expect(find.textContaining('Nameviewer-1: first'), findsOneWidget);
    expect(find.text('No messages in this chat yet'), findsNothing);
  });

  testWidgets('prefixes LIVE rows with the message timestamp', (tester) async {
    final stamp = DateTime(2026, 8, 9, 12, 29);
    store.appendChatMessageForTest(
      cardMessage('m1', 'viewer-1', 'hello', receivedAt: stamp),
    );

    userService.userResult = const TwitchUser(
      id: 'viewer-1',
      login: 'viewerlogin',
      displayName: 'ViewerOne',
    );

    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('${formatChatMessageTime(stamp)} '),
      findsOneWidget,
    );
  });

  testWidgets('LIVE rows are not compact so chat spacing applies',
      (tester) async {
    store.appendChatMessageForTest(cardMessage('m1', 'viewer-1', 'hello'));

    userService.userResult = const TwitchUser(
      id: 'viewer-1',
      login: 'viewerlogin',
      displayName: 'ViewerOne',
    );

    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    final row = tester.widget<TwitchChatMessageRow>(
      find.byType(TwitchChatMessageRow),
    );
    expect(row.compact, isFalse);
  });

  testWidgets('omits Helix fact rows when the service returns null',
      (tester) async {
    userService.userResult = null;
    userService.followResult = null;

    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    expect(find.textContaining('Account created on'), findsNothing);
    expect(find.textContaining('Following since'), findsNothing);
    expect(userService.fetchUserCalls, 1);
  });

  testWidgets('self footer exposes Log out when degraded', (tester) async {
    var loggedOut = false;
    userService.userResult = const TwitchUser(
      id: 'self-1',
      login: 'selflogin',
      displayName: 'SelfUser',
    );

    await openCard(
      tester,
      userId: 'self-1',
      connection: ChatUserCardConnection(
        chatType: ChatType.Twitch,
        status: NativeChatConnectionStatus.failed,
        statusLabel: 'failed',
        statusColor: Colors.red,
        statusDetail: 'Could not connect',
        accountLabel: 'SelfUser',
        onLogout: () => loggedOut = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not connect'), findsOneWidget);
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });
}
