import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_youtube_services.dart';

YouTubeChatMessage ytMessage(
  String id, {
  String author = 'chan-1',
  String? text,
}) =>
    YouTubeChatMessage(
      id: id,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.textMessage,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: author,
        displayMessage: text ?? 'text $id',
        textMessageDetails:
            YouTubeTextMessageDetails(messageText: text ?? 'text $id'),
      ),
      authorDetails: YouTubeChatAuthorDetails(
        channelId: author,
        displayName: 'User $author',
      ),
    );

YouTubeChatMessage ytTombstone(String id) => YouTubeChatMessage(
      id: id,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.tombstone,
        publishedAt: DateTime.utc(2026, 9, 3),
      ),
    );

YouTubeChatMessage ytUserBanned(String bannedChannelId) => YouTubeChatMessage(
      id: 'ban-$bannedChannelId',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.userBanned,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'mod-1',
        userBannedDetails: YouTubeUserBannedDetails(
          banType: 'permanent',
          bannedUserDetails:
              YouTubeBannedUserDetails(channelId: bannedChannelId),
        ),
      ),
    );

YouTubeLiveChatPage page(
  List<YouTubeChatMessage> messages, {
  String? nextPageToken,
  int pollingIntervalMillis = 1000,
  DateTime? offlineAt,
}) =>
    YouTubeLiveChatPage(
      messages: messages,
      nextPageToken: nextPageToken,
      pollingIntervalMillis: pollingIntervalMillis,
      offlineAt: offlineAt,
    );

/// Waits until [condition] holds (the poll loop progresses on the event
/// loop — instant injected sleep) or ~1s passes.
Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 1000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeYouTubeAuthService authService;
  late FakeYouTubeLiveChatService chatService;
  late List<Duration> sleepLog;
  late YouTubeChatStore store;

  Box<YouTubeAuth> authBox() =>
      Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  YouTubeChatStore newStore() => YouTubeChatStore(
        authService: authService,
        chatService: chatService,
        sleep: (duration) async {
          sleepLog.add(duration);
        },
      );

  /// Configured state: API key + two channels ('A' → video-a-001,
  /// 'B' → video-b-002).
  void configure() {
    settingsBox().put(SettingsKeys.YouTubeApiKey.name, 'api-key');
    settingsBox().put(SettingsKeys.YouTubeUsernames.name, <String, String>{
      'A': 'video-a-001',
      'B': 'https://www.youtube.com/watch?v=video-b-002',
    });
  }

  Future<void> seedAuth({List<String>? scopes}) => authBox().put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'access-1',
          refreshToken: 'refresh-1',
          expiresAtMs:
              DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
          scopes: scopes ?? kYouTubeChatScopes,
          channelTitle: 'My Channel',
        ),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('youtube_store_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await Hive.openBox(HiveKeys.Settings.name);
    authService = FakeYouTubeAuthService();
    chatService = FakeYouTubeLiveChatService();
    sleepLog = <Duration>[];
    store = newStore();
  });

  tearDown(() async {
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('init', () {
    test('unconfigured without an API key — even with a stored session',
        () async {
      await seedAuth();

      await store.init();

      expect(store.authState, YouTubeAuthState.unconfigured);
      expect(store.isConfigured, isFalse);
      expect(store.canRead, isFalse);
      expect(chatService.resolveCalls, 0);
    });

    test('configured without a stored session → signed out', () async {
      configure();

      await store.init();

      expect(store.authState, YouTubeAuthState.signedOut);
      expect(store.isSignedIn, isFalse);
      expect(store.canWrite, isFalse);
    });

    test('stored session → signed in, channel title exposed', () async {
      configure();
      await seedAuth();

      await store.init();

      expect(store.authState, YouTubeAuthState.signedIn);
      expect(store.isSignedIn, isTrue);
      expect(store.canWrite, isTrue);
      expect(store.selfChannelTitle, 'My Channel');
    });

    test('dead refresh token (400) → wiped + signed out', () async {
      configure();
      await seedAuth();
      // Force a refresh on init: expire the stored access token.
      final auth = authBox().get(YouTubeAuth.kBoxKey)!;
      auth.expiresAtMs = DateTime.now().millisecondsSinceEpoch - 1000;
      await auth.save();
      authService.failRefreshWith = const YouTubeAuthException(
        'Token refresh failed (400)',
        statusCode: 400,
      );

      await store.init();

      expect(store.authState, YouTubeAuthState.signedOut);
      expect(store.authError, isNotNull);
      expect(authBox().get(YouTubeAuth.kBoxKey), isNull);
    });
  });

  group('channels from settings', () {
    test('parses ids out of raw values, skips unparseable entries',
        () async {
      configure();
      settingsBox().put(SettingsKeys.YouTubeUsernames.name, <String, String>{
        'A': 'video-a-001',
        'B': 'https://www.youtube.com/watch?v=video-b-002',
        'broken': 'not a video id at all',
      });

      await store.init();

      expect(store.channels.map((c) => c.label), ['A', 'B']);
      expect(store.channels.map((c) => c.videoId),
          ['video-a-001', 'video-b-002']);
    });
  });

  group('polling', () {
    test('buffers messages across multiple poll pages, threading the page '
        'token', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.addAll([
        page([ytMessage('m1'), ytMessage('m2')], nextPageToken: 't1'),
        page([ytMessage('m3'), ytMessage('m4')]),
      ]);

      await store.init();
      await until(() => chatService.listCalls >= 3);

      expect(store.selectedChannelLabel, 'A');
      expect(store.chatConnection, YouTubeChatConnectionState.connected);
      expect(store.messages.map((m) => m.id), ['m1', 'm2', 'm3', 'm4']);
      expect(chatService.listPageTokens, [null, 't1', null]);
    });

    test('video without an active chat → offline, no error', () async {
      configure();
      // No liveChatIds entry → resolves null (not live).

      await store.init();
      await until(() => chatService.resolveCalls >= 1);
      await until(() =>
          store.chatConnection == YouTubeChatConnectionState.offline);

      expect(store.chatConnection, YouTubeChatConnectionState.offline);
      expect(store.chatError, isNull);
      expect(chatService.listCalls, 0);
    });

    test('chatEnded exception → offline, loop stops', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses
          .add(const YouTubeChatEndedException('Listing chat failed'));

      await store.init();
      await until(() =>
          store.chatConnection == YouTubeChatConnectionState.offline);

      expect(store.chatConnection, YouTubeChatConnectionState.offline);
      expect(store.chatError, isNull);
      expect(chatService.listCalls, 1);
    });

    test('quota exceeded → error + quota flag, polling stops', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses
          .add(const YouTubeQuotaExceededException('Listing chat failed'));

      await store.init();
      await until(() => store.chatQuotaExhausted);
      // Give a stopped loop the chance to misbehave.
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      expect(store.chatConnection, YouTubeChatConnectionState.error);
      expect(store.chatError, contains('quota'));
      expect(chatService.listCalls, 1);
    });

    test('rate limited → doubles the wait, then recovers', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.addAll([
        const YouTubeRateLimitedException('Listing chat failed'),
        page([ytMessage('m1')], pollingIntervalMillis: 2000),
      ]);

      await store.init();
      await until(() => chatService.listCalls >= 3);

      expect(store.chatConnection, YouTubeChatConnectionState.connected);
      expect(store.messages.map((m) => m.id), ['m1']);
      // Default interval 5s → first backoff 10s; success resets it and
      // the page's own 2s interval drives the next wait.
      expect(sleepLog, [
        const Duration(seconds: 10),
        const Duration(seconds: 2),
      ]);
    });

    test('repeated rate limiting caps the backoff at 60s', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.addAll([
        const YouTubeRateLimitedException('x'),
        const YouTubeRateLimitedException('x'),
        const YouTubeRateLimitedException('x'),
        const YouTubeRateLimitedException('x'),
        page(const []),
      ]);

      await store.init();
      await until(() => chatService.listCalls >= 6);

      expect(
        sleepLog.take(4),
        [
          const Duration(seconds: 10),
          const Duration(seconds: 20),
          const Duration(seconds: 40),
          const Duration(seconds: 60),
        ],
      );
      expect(store.chatConnection, YouTubeChatConnectionState.connected);
    });
  });

  group('channel switch', () {
    test('swaps buffers, resumes the buffered page token, persists the '
        'selection', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.liveChatIds['video-b-002'] = 'chat-b';
      chatService.pollResponses
          .add(page([ytMessage('a1')], nextPageToken: 'ta'));

      await store.init();
      // A consumes page 1, then parks (call 2 threads token 'ta').
      await until(() => chatService.listCalls >= 2);
      expect(store.messages.map((m) => m.id), ['a1']);
      expect(chatService.listPageTokens, [null, 'ta']);

      await store.selectChannel('B');
      expect(store.messages, isEmpty);
      // B resolves its liveChatId and parks on its first poll.
      await until(() => chatService.listCalls >= 3);
      chatService.pushPollResponse(page([ytMessage('b1')]));
      await until(() => store.messages.any((m) => m.id == 'b1'));

      expect(store.messages.map((m) => m.id), ['b1']);
      expect(
        settingsBox().get(SettingsKeys.SelectedYouTubeNativeChannelId.name),
        'B',
      );
      // B parks again after consuming the page.
      await until(() => chatService.listCalls >= 4);

      // Back to A: buffered history restored, poll resumes from 'ta'
      // without re-resolving the liveChatId.
      final resolveCallsBefore = chatService.resolveCalls;
      await store.selectChannel('A');
      expect(store.messages.map((m) => m.id), ['a1']);
      await until(() => chatService.listCalls >= 5);
      expect(chatService.listPageTokens.last, 'ta');
      chatService.pushPollResponse(page([ytMessage('a2')]));
      await until(() => store.messages.any((m) => m.id == 'a2'));

      expect(store.messages.map((m) => m.id), ['a1', 'a2']);
      expect(chatService.resolveCalls, resolveCallsBefore);
      expect(
        settingsBox().get(SettingsKeys.SelectedYouTubeNativeChannelId.name),
        'A',
      );
    });

    test('a fresh store restores the persisted selection on init', () async {
      configure();
      settingsBox()
          .put(SettingsKeys.SelectedYouTubeNativeChannelId.name, 'B');
      chatService.liveChatIds['video-b-002'] = 'chat-b';

      await store.init();
      await until(() => chatService.resolveCalls >= 1);

      expect(store.selectedChannelLabel, 'B');
    });
  });

  group('sendChatMessage', () {
    test('signed out → read-only no-op', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.add(page(const []));

      await store.init();
      await until(() =>
          store.chatConnection == YouTubeChatConnectionState.connected);

      expect(await store.sendChatMessage('hello'), isFalse);
      expect(chatService.insertCalls, 0);
    });

    test('signed in + connected → inserts and appends optimistically',
        () async {
      configure();
      await seedAuth();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.add(page(const []));

      await store.init();
      await until(() =>
          store.chatConnection == YouTubeChatConnectionState.connected);

      expect(await store.sendChatMessage('hello'), isTrue);
      expect(chatService.insertCalls, 1);
      expect(chatService.lastInsertMessage, 'hello');
      expect(store.messages.last.displayText, 'hello');
      expect(store.sendChatError, isNull);
    });

    test('API failure surfaces in sendChatError', () async {
      configure();
      await seedAuth();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.add(page(const []));
      chatService.insertThrows =
          const YouTubeForbiddenException('Sending chat message failed (403)');

      await store.init();
      await until(() =>
          store.chatConnection == YouTubeChatConnectionState.connected);

      expect(await store.sendChatMessage('hello'), isFalse);
      expect(store.sendChatError, contains('403'));
      expect(store.messages, isEmpty);
    });
  });

  group('lifecycle', () {
    Future<void> connectWith(YouTubeChatMessage message) async {
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.add(page([message]));
      await store.init();
      await until(() => store.messages.any((m) => m.id == message.id));
    }

    test('tombstone marks a buffered message; unknown ids are dropped',
        () async {
      configure();
      await connectWith(ytMessage('m1'));

      // Positive before: present, not tombstoned.
      expect(store.messages.single.id, 'm1');
      expect(store.messages.single.isTombstoned, isFalse);

      chatService.pushPollResponse(
          page([ytTombstone('m1'), ytTombstone('ghost')]));
      await until(() => store.messages.single.isTombstoned);

      // Negative after: tombstoned, still present, ghost never appended.
      expect(store.messages.single.id, 'm1');
      expect(store.messages.single.isTombstoned, isTrue);
    });

    test('userBanned purges only that author’s messages', () async {
      configure();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.add(page([
        ytMessage('m1', author: 'chan-1'),
        ytMessage('m2', author: 'chan-2'),
        ytMessage('m3', author: 'chan-1'),
      ]));
      await store.init();
      await until(() => store.messages.length == 3);

      expect(store.messages.any((m) => m.isTombstoned), isFalse);

      chatService.pushPollResponse(page([ytUserBanned('chan-1')]));
      await until(() => store.messages.any((m) => m.isTombstoned));

      expect(store.messages.length, 3,
          reason: 'the ban event itself is not appended as a row');
      expect(store.messages[0].isTombstoned, isTrue);
      expect(store.messages[1].isTombstoned, isFalse);
      expect(store.messages[2].isTombstoned, isTrue);
    });

    test('locally-initiated delete + echoed tombstone does not double-apply',
        () async {
      configure();
      await seedAuth();
      await connectWith(ytMessage('m1'));

      expect(await store.deleteMessage('m1'), isTrue);
      expect(chatService.deletedMessageIds, ['m1']);
      expect(store.messages.single.isTombstoned, isTrue);

      // The poll echo of our own delete must land as a no-op.
      final callsBefore = chatService.listCalls;
      chatService.pushPollResponse(page([ytTombstone('m1')]));
      await until(() => chatService.listCalls > callsBefore);

      expect(store.messages.single.id, 'm1');
      expect(store.messages.single.isTombstoned, isTrue);
    });

    test('locally-initiated ban + echoed userBanned does not double-apply',
        () async {
      configure();
      await seedAuth();
      await connectWith(ytMessage('m1', author: 'chan-1'));

      expect(await store.banUser('chan-1', durationSeconds: 300), isTrue);
      expect(chatService.banCalls,
          [(channelId: 'chan-1', durationSeconds: 300)]);
      expect(store.messages.single.isTombstoned, isTrue);

      final callsBefore = chatService.listCalls;
      chatService.pushPollResponse(page([ytUserBanned('chan-1')]));
      await until(() => chatService.listCalls > callsBefore);

      expect(store.messages.single.isTombstoned, isTrue);
    });

    test('delete failure surfaces in moderationError', () async {
      configure();
      await seedAuth();
      await connectWith(ytMessage('m1'));
      chatService.deleteThrows =
          const YouTubeForbiddenException('Deleting chat message failed (403)');

      expect(await store.deleteMessage('m1'), isFalse);
      expect(store.moderationError, contains('403'));
      expect(store.messages.single.isTombstoned, isFalse);
    });

    test('unban forwards the ban id', () async {
      configure();
      await seedAuth();
      await store.init();

      expect(await store.unbanUser('ban-1'), isTrue);
      expect(chatService.unbanCalls, ['ban-1']);
    });
  });

  group('startLogin', () {
    test('success persists the auth (with channel title) and signs in',
        () async {
      configure();

      await store.startLogin();

      expect(store.authState, YouTubeAuthState.signedIn);
      final stored = authBox().get(YouTubeAuth.kBoxKey);
      expect(stored?.accessToken, 'access-1');
      expect(stored?.channelTitle, 'My Channel');
      expect(store.pendingUserCode, isNull);
    });

    test('channel-title fetch failure does not fail the sign-in', () async {
      configure();
      authService.failChannelTitleWith =
          const YouTubeAuthException('Fetching the YouTube channel failed (500)');

      await store.startLogin();

      expect(store.authState, YouTubeAuthState.signedIn);
      expect(authBox().get(YouTubeAuth.kBoxKey)?.channelTitle, isNull);
    });

    test('cancelLogin returns to signed out without an error', () async {
      configure();
      final login = store.startLogin();
      store.cancelLogin();
      await login;

      expect(store.authState, YouTubeAuthState.signedOut);
      expect(store.authError, isNull);
      expect(authBox().get(YouTubeAuth.kBoxKey), isNull);
    });
  });

  group('logout', () {
    test('wipes the session, revokes and stops polling', () async {
      configure();
      await seedAuth();
      chatService.liveChatIds['video-a-001'] = 'chat-a';
      chatService.pollResponses.add(page([ytMessage('m1')]));
      await store.init();
      await until(() => store.messages.isNotEmpty);

      await store.logout();

      expect(store.authState, YouTubeAuthState.signedOut);
      expect(authBox().get(YouTubeAuth.kBoxKey), isNull);
      expect(store.messages, isEmpty);
      expect(store.chatConnection, YouTubeChatConnectionState.idle);
      expect(authService.revokedToken, 'access-1');
    });
  });
}
