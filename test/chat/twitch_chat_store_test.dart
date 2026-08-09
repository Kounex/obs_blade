import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/twitch_emotes.dart';
import 'package:obs_blade/types/classes/twitch/chat_system_notice.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_moderate_event.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/classes/twitch/twitch_drop_reason.dart';
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_tombstone.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

ChatMessageEvent chatMessage(String id, String chatterId) => ChatMessageEvent(
      broadcasterUserId: 'b1',
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
  late FakeTwitchBadgeService badgeService;
  late TwitchBadgeStore badgeStore;
  late TwitchChatStore store;

  Box<TwitchAuth> authBox() => Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_store_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    eventSubService = FakeTwitchEventSubService();
    badgeService = FakeTwitchBadgeService();
    badgeStore = TwitchBadgeStore(service: badgeService);
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
          eventSubService,
      badgeStoreResolver: () => badgeStore,
    );
  });

  tearDown(() async {
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('init', () {
    test('logged out without a stored record', () async {
      await store.init();
      expect(store.authState, TwitchAuthState.loggedOut);
    });

    test('valid stored token → logged in with the stored user', () async {
      await authBox().put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: const ['user:read:chat'],
          userId: 'user-1',
          userLogin: 'kounex',
          userDisplayName: 'Kounex',
        ),
      );

      await store.init();

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.isLoggedIn, isTrue);
      expect(store.user?.login, 'kounex');
    });

    test('invalid stored token → wiped + logged out', () async {
      authService.validateResult = false;
      await authBox().put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'stale',
          refreshToken: 'stale',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: const ['user:read:chat'],
        ),
      );

      await store.init();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
    });

    test('validate throwing (offline) keeps the record, stays logged out', () async {
      authService.validateThrows = const SocketException('Network unreachable');
      await authBox().put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: const ['user:read:chat'],
          userId: 'user-1',
          userLogin: 'kounex',
        ),
      );

      await store.init();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.isLoggedIn, isFalse);
      expect(authBox().get(TwitchAuth.kBoxKey), isNotNull);
      expect(eventSubService.connectCalled, isFalse);
    });

    test('validate throwing a Twitch 5xx keeps the record, stays logged out', () async {
      authService.validateThrows =
          const TwitchAuthException('Token validation failed (status 500)');
      await authBox().put(
        TwitchAuth.kBoxKey,
        TwitchAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: const ['user:read:chat'],
          userId: 'user-1',
          userLogin: 'kounex',
        ),
      );

      await store.init();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.isLoggedIn, isFalse);
      expect(authBox().get(TwitchAuth.kBoxKey), isNotNull);
      expect(eventSubService.connectCalled, isFalse);
    });
  });

  group('startLogin', () {
    test('success persists the auth, sets the user and connects chat', () async {
      await store.startLogin();

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.user?.login, 'kounex');
      final stored = authBox().get(TwitchAuth.kBoxKey);
      expect(stored?.accessToken, 'access-1');
      expect(stored?.userId, 'user-1');
      expect(eventSubService.connectCalled, isTrue);
      expect(eventSubService.lastAccessToken, 'access-1');
    });

    test('poll failure lands in error state without a stored record', () async {
      authService.failPollWith =
          const TwitchAuthException('Authorization denied on Twitch');

      await store.startLogin();

      expect(store.authState, TwitchAuthState.error);
      expect(store.authError, 'Authorization denied on Twitch');
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
      expect(eventSubService.connectCalled, isFalse);
    });

    test('cancelLogin returns to logged out without an error', () async {
      final login = store.startLogin();
      store.cancelLogin();
      await login;

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.authError, isNull);
    });

    test('cancelling a re-login upgrade keeps the live session', () async {
      await store.startLogin();
      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.user?.login, 'kounex');

      // Scope-upgrade re-login while logged in, cancelled mid-flow: the
      // persisted auth + live EventSub session were never torn down.
      final relogin = store.startLogin();
      store.cancelLogin();
      await relogin;

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.user?.login, 'kounex');
      expect(store.authError, isNull);
      expect(authBox().get(TwitchAuth.kBoxKey), isNotNull);
      expect(eventSubService.disposeCalled, isFalse);
    });

    test('a superseded login flow cannot clobber the new flow', () async {
      // Login A: the poll parks on a gate the test controls.
      final gateA = Completer<TwitchToken>();
      authService.pollGate = gateA;
      final loginA = store.startLogin();
      await pumpEventQueue();

      // The user cancels A and immediately restarts — login B succeeds.
      store.cancelLogin();
      authService.pollGate = null;
      await store.startLogin();
      expect(store.authState, TwitchAuthState.loggedIn);

      // A's stale poll now throws — it must not touch B's state.
      gateA.completeError(const TwitchAuthException('Login cancelled'));
      await loginA;
      await pumpEventQueue();

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.user?.login, 'kounex');
      expect(authBox().get(TwitchAuth.kBoxKey), isNotNull);
    });

    test('a superseded flow\'s stale poll success cannot clobber the new flow',
        () async {
      // Login A: the poll parks on a gate the test controls.
      final gateA = Completer<TwitchToken>();
      authService.pollGate = gateA;
      final loginA = store.startLogin();
      await pumpEventQueue();

      // The user restarts — login B supersedes A and succeeds.
      authService.pollGate = null;
      await store.startLogin();
      expect(store.authState, TwitchAuthState.loggedIn);

      // A's stale poll now RESOLVES successfully — its continuation must
      // bail instead of re-persisting and reconnecting (a reconnect would
      // dispose B's live EventSub session first).
      gateA.complete(FakeTwitchAuthService.token);
      await loginA;
      await pumpEventQueue();

      expect(store.authState, TwitchAuthState.loggedIn);
      expect(store.user?.login, 'kounex');
      expect(eventSubService.disposeCalled, isFalse);
    });
  });

  group('logout', () {
    test('wipes the box, revokes and disconnects chat', () async {
      await store.startLogin();
      expect(store.isLoggedIn, isTrue);

      await store.logout();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.user, isNull);
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
      expect(authService.revokedToken, 'access-1');
      expect(eventSubService.disposeCalled, isTrue);
    });

    test('supersedes an in-flight login flow', () async {
      // Login A parks mid-poll while the user logs out from another path.
      final gateA = Completer<TwitchToken>();
      authService.pollGate = gateA;
      final loginA = store.startLogin();
      await pumpEventQueue();
      expect(store.authState, TwitchAuthState.awaitingAuthorization);

      await store.logout();
      expect(store.authState, TwitchAuthState.loggedOut);

      // A's stale poll now resolves — its continuation must not revive
      // the login after the logout.
      gateA.complete(FakeTwitchAuthService.token);
      await loginA;
      await pumpEventQueue();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.user, isNull);
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
      expect(eventSubService.connectCalled, isFalse);
    });
  });

  group('connectChat', () {
    TwitchAuth recordInsideRefreshWindow() => TwitchAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          // Inside the 5-minute refresh window → connectChat refreshes
          // the token before connecting.
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 60 * 1000,
          scopes: const ['user:read:chat'],
          userId: 'user-1',
          userLogin: 'kounex',
        );

    test('a 5xx on token refresh keeps the session and fails the connection',
        () async {
      authService.failRefreshWith = const TwitchAuthException(
        'Token refresh failed (500)',
        statusCode: 500,
      );
      await authBox().put(TwitchAuth.kBoxKey, recordInsideRefreshWindow());

      await store.init();

      expect(store.chatConnection, TwitchChatConnectionState.failed);
      expect(store.chatError, 'Could not connect to Twitch chat');
      expect(store.authState, TwitchAuthState.loggedIn);
      expect(authBox().get(TwitchAuth.kBoxKey)?.accessToken, 'access-1');
      expect(eventSubService.connectCalled, isFalse);
    });

    test('a 401 on token refresh wipes the session', () async {
      authService.failRefreshWith = const TwitchAuthException(
        'Token refresh failed (401)',
        statusCode: 401,
      );
      await authBox().put(TwitchAuth.kBoxKey, recordInsideRefreshWindow());

      await store.init();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.authError, 'Token refresh failed (401)');
      expect(authBox().get(TwitchAuth.kBoxKey), isNull);
      expect(store.chatConnection, TwitchChatConnectionState.disconnected);
      expect(eventSubService.connectCalled, isFalse);
    });
  });

  group('external wipe (data management)', () {
    test('deleting the box record resets to logged out', () async {
      await store.startLogin();
      expect(store.isLoggedIn, isTrue);

      await authBox().delete(TwitchAuth.kBoxKey);
      await pumpEventQueue();

      expect(store.authState, TwitchAuthState.loggedOut);
      expect(store.user, isNull);
    });
  });

  group('message buffer', () {
    ChatMessageEvent event(String id) => ChatMessageEvent(
          broadcasterUserId: 'user-1',
          chatterUserId: id,
          chatterUserLogin: 'u$id',
          chatterUserName: 'User$id',
          messageId: id,
          message: ChatMessageText(
            text: 'msg $id',
            fragments: [
              ChatMessageFragment(type: 'text', text: 'msg $id'),
            ],
          ),
        );

    test('appends via the exposed action and trims at 500', () {
      for (var i = 0; i < 505; i++) {
        store.appendChatMessageForTest(event('$i'));
      }

      expect(store.messages, hasLength(500));
      expect(store.messages.first.messageId, '5');
      expect(store.messages.last.messageId, '504');
    });

    test('messagesForChatter returns newest-first capped rows for one user',
        () {
      ChatMessageEvent tagged(String id, String chatterId, {String? color}) =>
          ChatMessageEvent(
            broadcasterUserId: 'b1',
            chatterUserId: chatterId,
            chatterUserLogin: 'u$chatterId',
            chatterUserName: 'User$chatterId',
            messageId: id,
            color: color,
            message: ChatMessageText(
              text: 'msg $id',
              fragments: [
                ChatMessageFragment(type: 'text', text: 'msg $id'),
              ],
            ),
          );

      for (var i = 0; i < 25; i++) {
        store.appendChatMessageForTest(tagged('a$i', 'target'));
        store.appendChatMessageForTest(tagged('b$i', 'other'));
      }
      store.appendChatMessageForTest(
        tagged('latest', 'target', color: '#FF0000'),
      );

      final rows = store.messagesForChatter('target');

      expect(rows, hasLength(20));
      expect(rows.first.messageId, 'latest');
      expect(rows.last.messageId, 'a6');
      expect(store.newestChatterColor('target'), '#FF0000');
      expect(store.messagesForChatter('missing'), isEmpty);
    });
  });

  group('badge catalog wiring', () {
    Future<void> seedValidAuth() => authBox().put(
          TwitchAuth.kBoxKey,
          TwitchAuth(
            accessToken: 'access-1',
            refreshToken: 'refresh-1',
            expiresAtMs:
                DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
            scopes: const ['user:read:chat'],
            userId: 'user-1',
          ),
        );

    test('connectChat fetches badges for the logged-in user', () async {
      await seedValidAuth();
      store.authState = TwitchAuthState.loggedIn;
      store.user = FakeTwitchAuthService.user;

      await store.connectChat();

      expect(badgeService.globalCalls, 1);
      expect(badgeService.channelCalls, 1);
      expect(badgeService.lastAccessToken, 'access-1');
      expect(badgeService.lastBroadcasterId, 'user-1');
    });

    test('a failing badge fetch does not affect the chat connection',
        () async {
      badgeService.globalThrows =
          const TwitchAuthException('down', statusCode: 500);
      badgeService.channelThrows =
          const TwitchAuthException('down', statusCode: 500);
      await seedValidAuth();
      store.authState = TwitchAuthState.loggedIn;
      store.user = FakeTwitchAuthService.user;

      await store.connectChat();

      expect(store.chatConnection,
          isNot(TwitchChatConnectionState.failed));
      expect(store.chatError, isNull);
    });

    test('logout clears the badge catalog', () async {
      badgeService.globalSets = [FakeTwitchBadgeService.moderatorSet];
      await badgeStore.fetch(accessToken: 'access-1', broadcasterId: 'user-1');
      expect(badgeStore.globalBadges, isNotEmpty);

      await store.logout();

      expect(badgeStore.globalBadges, isEmpty);
      expect(badgeStore.channelBadges, isEmpty);
    });
  });

  group('chatConnectedAt', () {
    late void Function(TwitchEventSubState) emitState;
    late void Function(String) emitRevoked;

    /// A fresh store whose factory captures the callbacks the store hands
    /// to its EventSub service, so the test can drive state/revocation.
    Future<void> loginWithCapturedCallbacks() async {
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory:
            (_, __, ___, ____, _____, ______, onStateChanged, onRevoked) {
          emitState = onStateChanged;
          emitRevoked = onRevoked;
          return eventSubService;
        },
        badgeStoreResolver: () => badgeStore,
      );
      await store.startLogin();
    }

    test('stamped on live, kept on repeated live, re-stamped after reconnect',
        () async {
      await loginWithCapturedCallbacks();
      expect(store.chatConnectedAt, isNull);

      emitState(TwitchEventSubState.connected);
      final first = store.chatConnectedAt;
      expect(first, isNotNull);

      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, same(first));

      emitState(TwitchEventSubState.reconnecting);
      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, isNot(same(first)));
    });

    test('cleared on disconnect', () async {
      await loginWithCapturedCallbacks();
      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, isNotNull);

      emitState(TwitchEventSubState.disconnected);
      expect(store.chatConnectedAt, isNull);
    });

    test('cleared on subscription failure', () async {
      await loginWithCapturedCallbacks();
      emitState(TwitchEventSubState.connected);
      expect(store.chatConnectedAt, isNotNull);

      emitRevoked('subscription_failed:500');
      expect(store.chatConnection, TwitchChatConnectionState.failed);
      expect(store.chatConnectedAt, isNull);
    });
  });

  group('sendChatMessage', () {
    late FakeTwitchMessageService messageService;

    Future<void> login({List<String>? scopes}) async {
      authService.tokenScopes =
          scopes ?? const ['user:read:chat', 'user:write:chat'];
      messageService = FakeTwitchMessageService();
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
            eventSubService,
        badgeStoreResolver: () => badgeStore,
        messageService: messageService,
      );
      await store.startLogin();
    }

    test('canWriteChat reflects the persisted scopes', () async {
      await login(scopes: const ['user:read:chat']);
      expect(store.canWriteChat, isFalse);

      await login();
      expect(store.canWriteChat, isTrue);
    });

    test('sends trimmed text, returns true, clears state', () async {
      await login();

      expect(await store.sendChatMessage('  hello chat  '), isTrue);
      expect(messageService.lastMessage, 'hello chat');
      expect(store.sendingChat, isFalse);
      expect(store.sendChatError, isNull);
    });

    test('returns false without write scope and never calls the service',
        () async {
      await login(scopes: const ['user:read:chat']);

      expect(await store.sendChatMessage('hi'), isFalse);
      expect(messageService.calls, 0);
    });

    test('returns false for empty text and never calls the service',
        () async {
      await login();

      expect(await store.sendChatMessage('   '), isFalse);
      expect(messageService.calls, 0);
    });

    test('returns false while a send is in flight', () async {
      await login();
      messageService.sendGate = Completer<TwitchSendResult>();

      final first = store.sendChatMessage('one');
      expect(await store.sendChatMessage('two'), isFalse);
      expect(messageService.calls, 1);

      messageService.sendGate!.complete(
        const TwitchSendResult(messageId: 'msg-1', isSent: true),
      );
      expect(await first, isTrue);
      expect(store.sendingChat, isFalse);
    });

    test('dropped message maps the reason and returns false', () async {
      await login();
      messageService.result = const TwitchSendResult(
        messageId: '',
        isSent: false,
        dropReason: TwitchDropReason(code: 'automod_blocked'),
      );

      expect(await store.sendChatMessage('spam'), isFalse);
      expect(store.sendChatError, 'Message held by AutoMod');
      expect(store.sendingChat, isFalse);
    });

    test('dropped without a reason maps to the generic text', () async {
      await login();
      messageService.result = const TwitchSendResult(
        messageId: '',
        isSent: false,
      );

      expect(await store.sendChatMessage('spam'), isFalse);
      expect(store.sendChatError, 'Message not delivered');
    });

    test('dropped with an unknown code surfaces Twitch\'s own message',
        () async {
      await login();
      messageService.result = const TwitchSendResult(
        messageId: '',
        isSent: false,
        dropReason: TwitchDropReason(
          code: 'channel_settings_block',
          message: 'Your message was blocked by the channel settings.',
        ),
      );

      expect(await store.sendChatMessage('spam'), isFalse);
      expect(store.sendChatError,
          'Your message was blocked by the channel settings.');
    });

    test('dropped with an unknown code and no message shows the code',
        () async {
      await login();
      messageService.result = const TwitchSendResult(
        messageId: '',
        isSent: false,
        dropReason: TwitchDropReason(code: 'channel_settings_block'),
      );

      expect(await store.sendChatMessage('spam'), isFalse);
      expect(store.sendChatError,
          'Message not delivered (channel_settings_block)');
    });

    test('exception maps to the generic error and returns false', () async {
      await login();
      messageService.sendThrows =
          const TwitchAuthException('nope', statusCode: 401);

      expect(await store.sendChatMessage('hi'), isFalse);
      expect(store.sendChatError, 'Could not send — try again');
      expect(store.sendingChat, isFalse);
    });
  });

  group('third-party emote wiring', () {
    late FakeThirdPartyEmoteService emoteService;
    late ThirdPartyEmoteStore emoteStore;

    setUp(() {
      emoteService = FakeThirdPartyEmoteService();
      emoteStore = ThirdPartyEmoteStore(service: emoteService);
    });

    Future<void> logIn() async {
      await Hive.openBox(HiveKeys.Settings.name);
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
            eventSubService,
        badgeStoreResolver: () => badgeStore,
        emoteStoreResolver: () => emoteStore,
      );
      await store.startLogin();
    }

    test('connect fetches the emote catalogs for the logged-in user',
        () async {
      await logIn();

      expect(emoteService.sevenTvGlobalCalls, 1);
      expect(emoteService.sevenTvChannelCalls, 1);
      expect(emoteService.bttvGlobalCalls, 1);
      expect(emoteService.bttvChannelCalls, 1);
      expect(emoteService.lastBroadcasterId, FakeTwitchAuthService.user.id);
    });

    test('toggle off at connect skips the fetch', () async {
      await Hive.openBox(HiveKeys.Settings.name);
      await Hive.box(HiveKeys.Settings.name)
          .put(SettingsKeys.TwitchChatThirdPartyEmotes.name, false);

      await logIn();

      expect(emoteService.sevenTvGlobalCalls, 0);
      expect(emoteService.sevenTvChannelCalls, 0);
      expect(emoteService.bttvGlobalCalls, 0);
      expect(emoteService.bttvChannelCalls, 0);
    });

    test('logout clears the catalog', () async {
      await logIn();
      emoteStore.globalEmotes[FakeThirdPartyEmoteService.peepo.name] =
          FakeThirdPartyEmoteService.peepo;

      await store.logout();

      expect(emoteStore.globalEmotes, isEmpty);
      expect(emoteStore.channelEmotes, isEmpty);
    });
  });

  group('first-party emote wiring', () {
    late FakeTwitchEmoteService userEmoteService;
    late TwitchEmoteStore userEmoteStore;

    setUp(() {
      userEmoteService = FakeTwitchEmoteService();
      userEmoteStore = TwitchEmoteStore(service: userEmoteService);
    });

    Future<void> logIn({List<String>? scopes}) async {
      authService.tokenScopes = scopes ??
          const ['user:read:chat', 'user:write:chat', 'user:read:emotes'];
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
            eventSubService,
        badgeStoreResolver: () => badgeStore,
        userEmoteStoreResolver: () => userEmoteStore,
      );
      await store.startLogin();
    }

    test('connect fetches the user emote catalog when scoped', () async {
      await logIn();

      expect(store.canReadEmotes, isTrue);
      expect(userEmoteService.calls, 1);
      expect(userEmoteService.lastUserId, FakeTwitchAuthService.user.id);
      expect(
          userEmoteService.lastBroadcasterId, FakeTwitchAuthService.user.id);
      expect(userEmoteService.lastAccessToken,
          FakeTwitchAuthService.token.accessToken);
    });

    test('a pre-upgrade token skips the fetch', () async {
      await logIn(scopes: const ['user:read:chat', 'user:write:chat']);

      expect(store.canReadEmotes, isFalse);
      expect(userEmoteService.calls, 0);
    });

    test('logout clears the catalog', () async {
      await logIn();
      userEmoteStore.channelEmotes.add(FakeTwitchEmoteService.channelEmote);

      await store.logout();

      expect(userEmoteStore.channelEmotes, isEmpty);
      expect(userEmoteStore.globalEmotes, isEmpty);
    });
  });

  group('lifecycle', () {
    test('deleting a visible message tombstones it and bumps the version', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.lifecycleVersion, version + 1);
    });

    test('deleting an unknown id is a no-op', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'nope', targetUserId: 'u1', userName: 'Cool_Mod'));

      expect(store.isMessageDeleted('nope'), isFalse);
      expect(store.lifecycleVersion, version);
    });

    test('user purge tombstones only that user and is idempotent', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));
      store.appendChatMessageForTest(chatMessage('m3', 'u2'));

      store.applyClearUserMessages('u2');

      expect(store.isMessageDeleted('m1'), isFalse);
      expect(store.isMessageDeleted('m2'), isTrue);
      expect(store.isMessageDeleted('m3'), isTrue);
      final version = store.lifecycleVersion;

      store.applyClearUserMessages('u2');
      expect(store.lifecycleVersion, version);
    });

    test('chat clear tombstones everything and banners between old and new', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));

      store.applyChatClear();

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.isMessageDeleted('m2'), isTrue);
      expect(store.systemNotices.single.kind, ChatSystemNoticeKind.chatCleared);

      store.appendChatMessageForTest(chatMessage('m3', 'u1'));
      final items = store.messagesWithNotices();
      expect(items, hasLength(4));
      expect(items[0], isA<ChatMessageEvent>());
      expect(items[1], isA<ChatMessageEvent>());
      expect(items[2], isA<ChatSystemNotice>());
      expect(items[3], isA<ChatMessageEvent>());
    });

    test('chat clear on an empty chat is a full no-op', () {
      final version = store.lifecycleVersion;

      store.applyChatClear();

      expect(store.systemNotices, isEmpty);
      expect(store.lifecycleVersion, version);
    });

    test('two clears keep banner order in the merged list', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyChatClear();
      store.appendChatMessageForTest(chatMessage('m2', 'u1'));
      store.applyChatClear();

      // runtimeType is the freezed _ChatMessageEvent, so assert with isA.
      final items = store.messagesWithNotices();
      expect(items, hasLength(4));
      expect(items[0], isA<ChatMessageEvent>());
      expect(items[1], isA<ChatSystemNotice>());
      expect(items[2], isA<ChatMessageEvent>());
      expect(items[3], isA<ChatSystemNotice>());
    });

    test('cap eviction prunes the tombstone set', () {
      // kMaxMessages lives on the private _TwitchChatStore — statics don't
      // cross the mixin-application alias, so the cap is literal here (same
      // as the 'message buffer' group above).
      for (var i = 0; i < 500; i++) {
        store.appendChatMessageForTest(chatMessage('m$i', 'u1'));
      }
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm0', targetUserId: 'u1', userName: 'Cool_Mod'));
      expect(store.isMessageDeleted('m0'), isTrue);
      expect(store.deletedMessageActor('m0'), 'Cool_Mod');

      store.appendChatMessageForTest(chatMessage('m500', 'u1'));

      expect(store.messages, hasLength(500));
      expect(store.isMessageDeleted('m0'), isFalse);
      expect(store.deletedMessageActor('m0'), isNull);
    });

    test('logout clears tombstones, notices and the arrival counter', () async {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
      store.applyChatClear();
      expect(store.systemNotices, isNotEmpty);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');

      await store.logout();

      expect(store.isMessageDeleted('m1'), isFalse);
      expect(store.deletedMessageActor('m1'), isNull);
      expect(store.systemNotices, isEmpty);

      /// Arrival seq restarted — the merged list has no stale notices.
      store.appendChatMessageForTest(chatMessage('m2', 'u1'));
      expect(store.messagesWithNotices(), hasLength(1));
    });

    test('deleting records the actor; purge and /clear record none', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));
      store.appendChatMessageForTest(chatMessage('m3', 'u3'));

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
      store.applyClearUserMessages('u2');
      store.applyChatClear();

      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.deletedMessageActor('m2'), isNull);
      expect(store.deletedMessageActor('m3'), isNull);
      expect(store.deletedMessageActor('nope'), isNull);
    });

    test('a moderate delete tombstones with the actor and bumps the version',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyModerationDelete('m1', 'Cool_Mod');

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.lifecycleVersion, version + 1);
    });

    test('message_delete first, moderate later — actor lands with a bump',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyMessageDelete(
          const ChatMessageDeleteEvent(messageId: 'm1', targetUserId: 'u1'));
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), isNull);
      final version = store.lifecycleVersion;

      store.applyModerationDelete('m1', 'Cool_Mod');

      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.lifecycleVersion, version + 1);
    });

    test('moderate first, message_delete later — idempotent single tombstone',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyModerationDelete('m1', 'Cool_Mod');
      final version = store.lifecycleVersion;

      store.applyMessageDelete(
          const ChatMessageDeleteEvent(messageId: 'm1', targetUserId: 'u1'));

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.lifecycleVersion, version);
    });

    test('a moderate delete for an unknown id is a no-op', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      final version = store.lifecycleVersion;

      store.applyModerationDelete('nope', 'Cool_Mod');

      expect(store.isMessageDeleted('nope'), isFalse);
      expect(store.lifecycleVersion, version);
    });

    test('timeout stamps Timed out markers; ban stamps Banned', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u1'));
      store.appendChatMessageForTest(chatMessage('m3', 'u2'));

      store.applyModerationTimeout('u1', const Duration(seconds: 600));

      expect(store.tombstoneInfo('m1')?.kind, ChatTombstoneKind.timedOut);
      expect(store.tombstoneInfo('m1')?.timeoutDuration,
          const Duration(seconds: 600));
      expect(store.tombstoneInfo('m2')?.kind, ChatTombstoneKind.timedOut);
      expect(store.isMessageDeleted('m3'), isFalse);

      store.applyModerationBan('u2');
      expect(store.tombstoneInfo('m3')?.kind, ChatTombstoneKind.banned);
    });

    test('clear_user_messages after timeout keeps the Timed out marker', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyModerationTimeout('u1', const Duration(minutes: 10));
      store.applyClearUserMessages('u1');

      expect(store.tombstoneInfo('m1')?.kind, ChatTombstoneKind.timedOut);
    });

    test('clear_user_messages before timeout upgrades Deleted to Timed out',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyClearUserMessages('u1');
      expect(store.tombstoneInfo('m1')?.kind, ChatTombstoneKind.deleted);

      store.applyModerationTimeout('u1', const Duration(minutes: 10));
      expect(store.tombstoneInfo('m1')?.kind, ChatTombstoneKind.timedOut);
    });
  });

  group('lifecycle wiring', () {
    late void Function(ChatMessageDeleteEvent) emitDelete;
    late void Function(ChatClearUserMessagesEvent) emitPurge;
    late void Function(ChatClearEvent) emitClear;
    late void Function(ChannelModerateEvent) emitModerate;

    /// A fresh store whose factory captures the lifecycle callbacks the
    /// store hands to its EventSub service (chatConnectedAt-group pattern).
    Future<void> loginWithCapturedCallbacks() async {
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (onChatMessage, onChatNotification, onMessageDelete,
            onClearUserMessages, onChatClear, onChannelModerate,
            onStateChanged, onRevoked) {
          emitDelete = onMessageDelete;
          emitPurge = onClearUserMessages;
          emitClear = onChatClear;
          emitModerate = onChannelModerate;
          return eventSubService;
        },
        badgeStoreResolver: () => badgeStore,
      );
      await store.startLogin();
    }

    test('EventSub lifecycle callbacks drive the store actions', () async {
      await loginWithCapturedCallbacks();
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));

      emitDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1', userName: 'Cool_Mod'));
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
      expect(store.isMessageDeleted('m2'), isFalse);

      emitPurge(const ChatClearUserMessagesEvent(targetUserId: 'u2'));
      expect(store.isMessageDeleted('m2'), isTrue);

      emitClear(const ChatClearEvent(broadcasterUserId: 'b1'));
      expect(store.systemNotices, hasLength(1));
    });

    test('the moderate callback drives the actor reveal', () async {
      await loginWithCapturedCallbacks();
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));

      emitModerate(const ChannelModerateEvent(
        action: 'delete',
        moderatorUserName: 'Cool_Mod',
        delete: ModerateDeleteAction(messageId: 'm1'),
      ));

      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Cool_Mod');
    });
  });

  group('moderation scope gate', () {
    test('connectChat passes includeModeration: false without the bundle',
        () async {
      authService.tokenScopes = const [
        'user:read:chat',
        'user:write:chat',
        'user:read:emotes',
      ];
      await store.startLogin();

      expect(eventSubService.lastIncludeModeration, isFalse);
    });

    test('connectChat passes includeModeration: true with the full bundle',
        () async {
      authService.tokenScopes = kTwitchModerationScopes;
      await store.startLogin();

      expect(eventSubService.lastIncludeModeration, isTrue);
    });
  });

  group('multi-channel', () {
    late FakeTwitchMessageService messageService;
    late FakeTwitchChannelService channelService;
    late void Function(TwitchEventSubState) emitState;

    TwitchChannelRef ref(String id) => TwitchChannelRef(
          id: id,
          login: 'login-$id',
          displayName: 'Channel $id',
          addedAt: DateTime.utc(2026, 8, 9),
        );

    Box settingsBox() => Hive.box(HiveKeys.Settings.name);

    setUp(() {
      messageService = FakeTwitchMessageService();
      channelService = FakeTwitchChannelService();
    });

    Future<void> login({List<String>? scopes}) async {
      await Hive.openBox(HiveKeys.Settings.name);
      authService.tokenScopes =
          scopes ?? const ['user:read:chat', 'user:write:chat'];
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___, ____, _____, ______, onStateChanged, ________) {
          emitState = onStateChanged;
          return eventSubService;
        },
        badgeStoreResolver: () => badgeStore,
        messageService: messageService,
        channelService: channelService,
      );
      await store.startLogin();
      emitState(TwitchEventSubState.connected);
    }

    test('addChannel dedupes by id, persists and selects the channel',
        () async {
      await login();

      await store.addChannel(ref('chan-1'));
      await store.addChannel(ref('chan-1'));

      expect(store.channels.map((entry) => entry.id), ['chan-1']);
      final stored =
          settingsBox().get(SettingsKeys.NativeChatChannels.name) as List;
      expect(stored, hasLength(1));
      expect((stored.single as Map)['id'], 'chan-1');
      expect(
          settingsBox().get(SettingsKeys.SelectedNativeChatChannelId.name),
          'chan-1');
      expect(store.selectedChannelId, 'chan-1');
      expect(store.effectiveBroadcasterId, 'chan-1');
      expect(eventSubService.lastSwitchBroadcasterId, 'chan-1');
    });

    test('channels and selection survive a store restart (settings round-trip)',
        () async {
      await login();
      await store.addChannel(ref('chan-1'));

      final restarted = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
            eventSubService,
        badgeStoreResolver: () => badgeStore,
        channelService: channelService,
      );
      await restarted.init();

      expect(restarted.channels.map((entry) => entry.id), ['chan-1']);
      expect(restarted.selectedChannelId, 'chan-1');
      expect(restarted.effectiveBroadcasterId, 'chan-1');

      /// Cold start connects straight into the persisted channel.
      expect(eventSubService.lastBroadcasterId, 'chan-1');
    });

    test('garbage in the settings box degrades to empty/null', () async {
      await Hive.openBox(HiveKeys.Settings.name);
      await settingsBox()
          .put(SettingsKeys.NativeChatChannels.name, ['nope', 42, {'id': 1}]);
      await settingsBox()
          .put(SettingsKeys.SelectedNativeChatChannelId.name, 42);

      await login();

      expect(store.channels, isEmpty);
      expect(store.selectedChannelId, isNull);
      expect(store.effectiveBroadcasterId, 'user-1');
    });

    test('switching snapshots and restores per-channel buffers', () async {
      await login();
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1'));

      await store.selectChannel('chan-1');
      expect(store.selectedChannelId, 'chan-1');
      expect(store.messages, isEmpty);
      expect(store.isMessageDeleted('m1'), isFalse);

      store.appendChatMessageForTest(chatMessage('m9', 'u9'));

      await store.selectChannel(null);
      expect(store.messages.map((message) => message.messageId), ['m1', 'm2']);
      expect(store.isMessageDeleted('m1'), isTrue);

      await store.selectChannel('chan-1');
      expect(store.messages.map((message) => message.messageId), ['m9']);
    });

    test('the chat bar shows connecting during a switch, live after', () async {
      await login();
      expect(store.chatConnection, TwitchChatConnectionState.live);

      await store.selectChannel('chan-1');
      expect(store.chatConnection, TwitchChatConnectionState.connecting);

      emitState(TwitchEventSubState.connected);
      expect(store.chatConnection, TwitchChatConnectionState.live);
    });

    test('selectChannel no-ops when unchanged or logged out', () async {
      await store.selectChannel('chan-1');
      expect(eventSubService.switchChannelCalls, 0);

      await login();
      await store.selectChannel(null);
      expect(eventSubService.switchChannelCalls, 0);
    });

    test('removeChannel drops the channel, its buffer and falls back to own',
        () async {
      await login();
      await store.addChannel(ref('chan-1'));
      store.appendChatMessageForTest(chatMessage('m9', 'u9'));
      expect(store.selectedChannelId, 'chan-1');

      await store.removeChannel('chan-1');

      expect(store.channels, isEmpty);
      expect(settingsBox().get(SettingsKeys.NativeChatChannels.name), isEmpty);
      expect(settingsBox().get(SettingsKeys.SelectedNativeChatChannelId.name),
          isNull);
      expect(store.selectedChannelId, isNull);
      expect(eventSubService.lastSwitchBroadcasterId, 'user-1');

      /// The buffer was dropped — re-adding starts with an empty chat.
      await store.addChannel(ref('chan-1'));
      expect(store.messages, isEmpty);
    });

    test('connectChat subscribes to the selected channel', () async {
      await login();
      await store.addChannel(ref('chan-1'));

      await store.connectChat();

      expect(eventSubService.lastBroadcasterId, 'chan-1');
    });

    test('sendChatMessage targets the effective broadcaster', () async {
      await login();
      await store.selectChannel('chan-9');

      expect(await store.sendChatMessage('hi'), isTrue);
      expect(messageService.lastSenderId, 'user-1');
      expect(messageService.lastBroadcasterId, 'chan-9');
    });

    test('login populates the moderated set when scoped', () async {
      channelService.moderatedChannels = [ref('chan-mod')];
      await login(scopes: const [
        'user:read:chat',
        'user:read:moderated_channels',
      ]);
      await pumpEventQueue();

      expect(channelService.moderatedCalls, 1);
      expect(channelService.lastModeratedUserId, 'user-1');
      expect(store.moderatedChannelIds, contains('chan-mod'));
    });

    test('a failing moderated fetch degrades to an empty set', () async {
      channelService.moderatedThrows =
          const TwitchAuthException('down', statusCode: 500);
      await login(scopes: const [
        'user:read:chat',
        'user:read:moderated_channels',
      ]);
      await pumpEventQueue();

      expect(store.moderatedChannelIds, isEmpty);
      expect(store.chatConnection, isNot(TwitchChatConnectionState.failed));
    });

    test('a pre-upgrade token skips the moderated fetch', () async {
      await login(scopes: const ['user:read:chat']);
      await pumpEventQueue();

      expect(channelService.moderatedCalls, 0);
    });

    test('gating — own / moderated / other channel with manage scopes',
        () async {
      await login(scopes: const [
        'user:read:chat',
        'user:write:chat',
        'moderator:manage:chat_messages',
        'moderator:manage:banned_users',
      ]);
      store.moderatedChannelIds.add('chan-mod');

      /// Own channel counts as full-mod implicitly.
      expect(store.canModerateSelectedChannel, isTrue);

      await store.selectChannel('chan-mod');
      expect(store.canModerateSelectedChannel, isTrue);

      await store.selectChannel('chan-other');
      expect(store.canModerateSelectedChannel, isFalse);
    });

    test('gating — pre-upgrade token cannot moderate anywhere', () async {
      await login(scopes: const [
        'user:read:chat',
        'user:read:moderated_channels',
      ]);
      store.moderatedChannelIds.add('chan-mod');

      expect(store.canModerateSelectedChannel, isFalse);

      await store.selectChannel('chan-mod');
      expect(store.canModerateSelectedChannel, isFalse);
    });

    test('repeat delete events for the same id apply once', () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1'));
      final version = store.lifecycleVersion;

      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1'));

      expect(store.lifecycleVersion, version);
      expect(store.isMessageDeleted('m1'), isTrue);
    });

    test('a duplicate /clear does not double-banner; a real second one does',
        () {
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.applyChatClear();
      expect(store.systemNotices, hasLength(1));

      /// Same arrival seq = same /clear delivered twice — deduped.
      store.applyChatClear();
      expect(store.systemNotices, hasLength(1));

      /// Messages after the clear move the seq — a genuine second /clear.
      store.appendChatMessageForTest(chatMessage('m2', 'u1'));
      store.applyChatClear();
      expect(store.systemNotices, hasLength(2));
    });
  });

  group('mod actions', () {
    late FakeTwitchModerationService moderationService;

    setUp(() {
      moderationService = FakeTwitchModerationService();
    });

    /// Own channel with manage scopes by default — the local user counts
    /// as a full mod there.
    Future<void> login({List<String>? scopes}) async {
      await Hive.openBox(HiveKeys.Settings.name);
      authService.tokenScopes = scopes ??
          const [
            'user:read:chat',
            'user:write:chat',
            'moderator:manage:chat_messages',
            'moderator:manage:banned_users',
          ];
      store = TwitchChatStore(
        authService: authService,
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
            eventSubService,
        badgeStoreResolver: () => badgeStore,
        moderationService: moderationService,
      );
      await store.startLogin();
    }

    test('deleteMessage hits the service and tombstones locally with self '
        'as actor', () async {
      await login();
      final event = chatMessage('m1', 'u1');
      store.appendChatMessageForTest(event);

      final ok = await store.deleteMessage(event);

      expect(ok, isTrue);
      expect(moderationService.deleteCalls, 1);
      expect(moderationService.lastDeleteBroadcasterId, 'user-1');
      expect(moderationService.lastDeleteModeratorId, 'user-1');
      expect(moderationService.lastDeleteMessageId, 'm1');
      expect(store.isMessageDeleted('m1'), isTrue);
      expect(store.deletedMessageActor('m1'), 'Kounex');
    });

    test('the EventSub echoes of a local delete do not double-apply',
        () async {
      await login();
      final event = chatMessage('m1', 'u1');
      store.appendChatMessageForTest(event);
      await store.deleteMessage(event);
      final version = store.lifecycleVersion;

      /// channel.chat.message_delete echo — same dedup key, skipped.
      store.applyMessageDelete(const ChatMessageDeleteEvent(
          messageId: 'm1', targetUserId: 'u1'));
      expect(store.lifecycleVersion, version);

      /// channel.moderate delete echo — same actor, skipped too.
      store.applyModerationDelete('m1', 'Kounex');
      expect(store.lifecycleVersion, version);
      expect(store.deletedMessageActor('m1'), 'Kounex');
    });

    test('timeoutUser hits the service with the duration and purges '
        'locally', () async {
      await login();
      store.appendChatMessageForTest(chatMessage('m1', 'u1'));
      store.appendChatMessageForTest(chatMessage('m2', 'u2'));
      store.appendChatMessageForTest(chatMessage('m3', 'u2'));

      final ok = await store.timeoutUser('u2', 600);

      expect(ok, isTrue);
      expect(moderationService.banCalls, 1);
      expect(moderationService.lastBanBroadcasterId, 'user-1');
      expect(moderationService.lastBanModeratorId, 'user-1');
      expect(moderationService.lastBanUserId, 'u2');
      expect(moderationService.lastBanDurationSeconds, 600);
      expect(store.isMessageDeleted('m1'), isFalse);
      expect(store.isMessageDeleted('m2'), isTrue);
      expect(store.isMessageDeleted('m3'), isTrue);
    });

    test('banUser omits the duration; the purge echo is deduped', () async {
      await login();
      store.appendChatMessageForTest(chatMessage('m1', 'u2'));

      final ok = await store.banUser('u2');

      expect(ok, isTrue);
      expect(moderationService.lastBanUserId, 'u2');
      expect(moderationService.lastBanDurationSeconds, isNull);
      expect(store.isMessageDeleted('m1'), isTrue);

      /// clear_user_messages echo of the ban — same dedup key, skipped.
      final version = store.lifecycleVersion;
      store.applyClearUserMessages('u2');
      expect(store.lifecycleVersion, version);
    });

    test('failures return false and leave local state untouched', () async {
      await login();
      final event = chatMessage('m1', 'u1');
      store.appendChatMessageForTest(event);
      final version = store.lifecycleVersion;

      moderationService.deleteThrows = const TwitchAuthException('down');
      expect(await store.deleteMessage(event), isFalse);
      expect(store.isMessageDeleted('m1'), isFalse);

      moderationService.banThrows = const TwitchAuthException('down');
      expect(await store.timeoutUser('u1', 600), isFalse);
      expect(store.isMessageDeleted('m1'), isFalse);
      expect(store.lifecycleVersion, version);
    });

    test('gated off without manage scopes and in non-moderated channels',
        () async {
      await login(scopes: const ['user:read:chat']);
      expect(await store.deleteMessage(chatMessage('m1', 'u1')), isFalse);

      /// Manage scopes, but the selected channel is not moderated.
      await login();
      store.selectedChannelId = 'chan-other';
      expect(store.canModerateSelectedChannel, isFalse);
      expect(await store.banUser('u1'), isFalse);
      expect(moderationService.banCalls, 0);
      expect(moderationService.deleteCalls, 0);
    });
  });
}
