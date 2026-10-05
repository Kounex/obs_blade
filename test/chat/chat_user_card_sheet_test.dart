import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/chat_history.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/chat_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/user_card_history_list.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

ChatMessageEvent cardMessage(
  String id,
  String userId,
  String text, {
  DateTime? receivedAt,
}) => ChatMessageEvent(
  broadcasterUserId: 'self-1',
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
  late FakeTwitchModerationService moderationService;
  late TwitchChatStore store;
  late ChatHistoryStore history;

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
    moderationService = FakeTwitchModerationService();

    history = ChatHistoryStore();
    store = TwitchChatStore(
      authService: authService,
      ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
      eventSubFactory:
          (
            _,
            __,
            ___,
            ____,
            _____,
            ______,
            _______,
            ________,
            _________,
            __________,
          ) => eventSubService,
      badgeStoreResolver: () => TwitchBadgeStore(service: badgeService),
      moderationService: moderationService,
      chatHistoryResolver: () => history,
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

  /// Grants extra scopes on the persisted token. No save(): the box serves
  /// this same in-memory instance on get(), and a Hive write (real I/O)
  /// would never complete inside testWidgets' fake async zone.
  void grantScopes(List<String> extra) {
    final authBox = Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);
    final auth = authBox.get(TwitchAuth.kBoxKey)!;
    auth.scopes = [...auth.scopes, ...extra];
  }

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

  testWidgets('LIVE rows are not compact so chat spacing applies', (
    tester,
  ) async {
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

  testWidgets('omits Helix fact rows when the service returns null', (
    tester,
  ) async {
    userService.userResult = null;
    userService.followResult = null;

    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    expect(find.textContaining('Account created on'), findsNothing);
    expect(find.textContaining('Following since'), findsNothing);
    expect(userService.fetchUserCalls, 1);
  });

  testWidgets('self footer exposes Sign out when degraded', (tester) async {
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
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });

  /// User request: only the history below LIVE scrolls - name, facts,
  /// LIVE and the self card's account footer stay where they are
  testWidgets('a long history scrolls between the pinned LIVE line and the '
      'pinned account footer', (tester) async {
    /// A portrait phone - a short sheet scrolls as a whole
    tester.view.physicalSize = const Size(390.0, 844.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    for (var i = 0; i < 30; i++) {
      store.appendChatMessageForTest(
        cardMessage('m$i', 'self-1', 'message number $i with a few words'),
      );
    }
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
        status: NativeChatConnectionStatus.live,
        statusLabel: '',
        statusColor: Colors.grey,
        accountLabel: 'SelfUser',
        onLogout: () {},
      ),
    );
    await tester.pumpAndSettle();

    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final live = find.text('LIVE');
    final signOut = find.text('Sign out');
    final liveBefore = tester.getTopLeft(live);
    final signOutBefore = tester.getTopLeft(signOut);
    expect(signOutBefore.dy, lessThan(screen));

    final newest = find.textContaining(
      'message number 29 ',
      findRichText: true,
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(UserCardHistoryList),
        matching: find.byType(Scrollable),
      ),
    );
    final pixelsBefore = scrollable.position.pixels;
    await tester.drag(newest, const Offset(0.0, -200.0));
    await tester.pumpAndSettle();

    /// The history scrolled under the pinned chrome (the dragged row may
    /// leave the viewport - the list builds lazily).
    expect(scrollable.position.pixels, greaterThan(pixelsBefore));
    expect(tester.getTopLeft(live), liveBefore);
    expect(tester.getTopLeft(signOut), signOutBefore);
  });

  /// Review finding: on a small phone with large text, the footer used
  /// to take all the room - the history vanished, Sign out overflowed
  testWidgets('small phone, large text, reconnecting: the history keeps '
      'room and nothing overflows', (tester) async {
    tester.view.physicalSize = const Size(375.0, 667.0);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (var i = 0; i < 30; i++) {
      store.appendChatMessageForTest(
        cardMessage('m$i', 'self-1', 'message number $i'),
      );
    }
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
        statusDetail:
            'Could not connect - the chat server closed the '
            'connection. Check your network and try again.',
        accountLabel: 'SelfUser',
        onRetry: () {},
        onLogout: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final newest = find.textContaining('message number 29', findRichText: true);
    final live = tester.getRect(find.text('LIVE'));
    final history = tester.getRect(newest);
    expect(history.top, greaterThan(live.bottom));
    final screen =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getRect(find.byType(ChatUserCardSheet)).bottom,
      lessThanOrEqualTo(screen),
    );

    /// The history keeps at least a third of the room: its newest row is
    /// on screen above the footer
    expect(history.bottom, lessThan(screen));
    await tester.ensureVisible(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out').hitTestable(), findsOneWidget);
  });

  testWidgets('small phone, normal text: Sign out shows without scrolling '
      'the footer', (tester) async {
    tester.view.physicalSize = const Size(375.0, 667.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    for (var i = 0; i < 30; i++) {
      store.appendChatMessageForTest(
        cardMessage('m$i', 'self-1', 'message number $i'),
      );
    }
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
        status: NativeChatConnectionStatus.live,
        statusLabel: '',
        statusColor: Colors.grey,
        accountLabel: 'SelfUser',
        onLogout: () {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign out').hitTestable(), findsOneWidget);
    expect(
      find
          .textContaining('message number 29', findRichText: true)
          .hitTestable(),
      findsOneWidget,
    );
  });

  /// The reported case: the chat bar has no account chip, so the self
  /// card the header opens must offer sign-out while the chat is healthy
  testWidgets('self footer exposes Sign out while live', (tester) async {
    var signedOut = false;
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
        status: NativeChatConnectionStatus.live,
        statusLabel: '',
        statusColor: Colors.grey,
        accountLabel: 'SelfUser',
        onLogout: () => signedOut = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connected as SelfUser'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
  });

  /// The own card the Twitch header opens (signed in, any channel viewed):
  /// Sign out in every chat state - offline included, which used to say
  /// "connect your Twitch account" while signed in.
  for (final status in NativeChatConnectionStatus.values) {
    testWidgets('self footer, ${status.name}: Sign out', (tester) async {
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
          status: status,
          statusLabel: status.name,
          statusColor: Colors.grey,
          accountLabel: 'SelfUser',
          onRetry: () {},
          onConnect: () {},
          onLogout: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('Connect Twitch'), findsNothing);
    });
  }

  testWidgets('mod view lists the user\'s warnings (newest channel '
      'warnings first)', (tester) async {
    grantScopes(kTwitchModerationScopes);

    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    expect(moderationService.getWarningsCalls, 1);
    expect(moderationService.lastWarningsUserId, 'viewer-1');

    final expectedDate = DateFormat.yMMMMd().format(
      FakeTwitchModerationService.warningSample.warnedAt!.toLocal(),
    );
    expect(find.text('Warned $expectedDate - spoiling movies'), findsOneWidget);
  });

  testWidgets('the self card hides the warnings section', (tester) async {
    grantScopes(kTwitchModerationScopes);

    await openCard(tester, userId: 'self-1');
    await tester.pumpAndSettle();

    expect(moderationService.getWarningsCalls, 0);
    expect(find.textContaining('Warned'), findsNothing);
  });

  testWidgets('without the moderation read bundle the section stays hidden', (
    tester,
  ) async {
    await openCard(tester, userId: 'viewer-1');
    await tester.pumpAndSettle();

    expect(moderationService.getWarningsCalls, 0);
    expect(find.textContaining('Warned'), findsNothing);
  });

  group('session history', () {
    /// [viewerCount] messages from viewer-1, then 500 filler rows from
    /// someone else - the viewer's rows all leave the 500-row buffer into
    /// the session history.
    void seedEvictedViewer(int viewerCount) {
      for (var i = 0; i < viewerCount; i++) {
        store.appendChatMessageForTest(
          cardMessage('old-$i', 'viewer-1', 'old $i'),
        );
      }
      for (var i = 0; i < 500; i++) {
        store.appendChatMessageForTest(
          cardMessage('f$i', 'other-1', 'filler $i'),
        );
      }
    }

    void viewerCard() {
      userService.userResult = const TwitchUser(
        id: 'viewer-1',
        login: 'viewerlogin',
        displayName: 'ViewerOne',
      );
    }

    testWidgets('a chatter fully evicted from the buffer still shows their '
        'history', (tester) async {
      seedEvictedViewer(5);
      expect(store.messages.any((m) => m.chatterUserId == 'viewer-1'), isFalse);
      viewerCard();

      await openCard(tester, userId: 'viewer-1');
      await tester.pumpAndSettle();

      expect(find.text('No messages in this chat yet'), findsNothing);
      expect(find.textContaining('Nameviewer-1: old 4'), findsOneWidget);
      expect(find.textContaining('Nameviewer-1: old 0'), findsOneWidget);
    });

    testWidgets('history rows render below the live rows (newest first)', (
      tester,
    ) async {
      seedEvictedViewer(1);
      store.appendChatMessageForTest(
        cardMessage('live-1', 'viewer-1', 'still live'),
      );
      viewerCard();

      await openCard(tester, userId: 'viewer-1');
      await tester.pumpAndSettle();

      final live = tester.getTopLeft(find.textContaining('still live'));
      final old = tester.getTopLeft(find.textContaining('old 0'));
      expect(live.dy, lessThan(old.dy));
    });

    testWidgets('50 rows shown, the button reveals the rest (lazily)', (
      tester,
    ) async {
      seedEvictedViewer(60);
      viewerCard();

      await openCard(tester, userId: 'viewer-1');
      await tester.pumpAndSettle();

      final scrollable = find.descendant(
        of: find.byType(UserCardHistoryList),
        matching: find.byType(Scrollable),
      );

      /// The newest retained row shows; rows past the first 50 (and the
      /// button itself) are offscreen and not even built.
      expect(find.textContaining('old 59'), findsOneWidget);
      expect(find.textContaining('old 9'), findsNothing);
      expect(find.text('Show 10 older messages'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Show 10 older messages'),
        300.0,
        scrollable: scrollable,
      );
      expect(
        find.bySemanticsLabel('Show 10 older messages from ViewerOne'),
        findsOneWidget,
      );

      await tester.tap(find.text('Show 10 older messages'));
      await tester.pumpAndSettle();

      expect(find.text('Show 10 older messages'), findsNothing);

      /// Expanded rows past the fold build on scroll, not on tap.
      expect(find.textContaining('old 0'), findsNothing);
      await tester.scrollUntilVisible(
        find.textContaining('old 0'),
        300.0,
        scrollable: scrollable,
      );
      expect(find.textContaining('old 0'), findsOneWidget);
    });

    testWidgets('no button at 50 retained rows or fewer', (tester) async {
      seedEvictedViewer(50);
      viewerCard();

      await openCard(tester, userId: 'viewer-1');
      await tester.pumpAndSettle();

      expect(find.textContaining('Show '), findsNothing);
      expect(find.textContaining('old 49'), findsOneWidget);
    });
  });
}
