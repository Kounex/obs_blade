import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_token.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeTwitchAuthService authService;
  late FakeTwitchEventSubService eventSubService;
  late TwitchChatStore store;

  Box<TwitchAuth> authBox() => Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_store_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
    authService = FakeTwitchAuthService();
    eventSubService = FakeTwitchEventSubService();
    store = TwitchChatStore(
      authService: authService,
      eventSubFactory: (_, __, ___) => eventSubService,
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
}
