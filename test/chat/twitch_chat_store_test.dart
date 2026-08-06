import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_drop_reason.dart';
import 'package:obs_blade/types/classes/twitch/twitch_send_result.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

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
      eventSubFactory: (_, __, ___) => eventSubService,
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
        eventSubFactory: (onChatMessage, onStateChanged, onRevoked) {
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
        eventSubFactory: (_, __, ___) => eventSubService,
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
        eventSubFactory: (_, __, ___) => eventSubService,
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
      emoteStore.emotes[FakeThirdPartyEmoteService.peepo.name] =
          FakeThirdPartyEmoteService.peepo;

      await store.logout();

      expect(emoteStore.emotes, isEmpty);
    });
  });
}
