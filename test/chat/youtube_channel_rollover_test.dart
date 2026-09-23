import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube_target.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_youtube_services.dart';

YouTubeChatMessage _message(String id) => YouTubeChatMessage(
  id: id,
  snippet: YouTubeChatMessageSnippet(
    type: YouTubeChatMessageType.textMessage,
    publishedAt: DateTime.utc(2026, 9, 24),
    authorChannelId: 'chan-1',
    displayMessage: 'text $id',
    textMessageDetails: YouTubeTextMessageDetails(messageText: 'text $id'),
  ),
  authorDetails: const YouTubeChatAuthorDetails(
    channelId: 'chan-1',
    displayName: 'User',
  ),
);

YouTubeLiveChatPage _page(
  List<YouTubeChatMessage> messages, {
  String? nextPageToken,
  DateTime? offlineAt,
}) => YouTubeLiveChatPage(
  messages: messages,
  nextPageToken: nextPageToken,
  pollingIntervalMillis: 1000,
  offlineAt: offlineAt,
);

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 1000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeYouTubeLiveChatService chatService;
  late FakeYouTubeLiveResolver resolver;
  late List<Duration> sleepLog;
  late YouTubeChatStore store;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  YouTubeChatStore newStore() => YouTubeChatStore(
    authService: FakeYouTubeAuthService(),
    chatService: chatService,
    liveResolver: resolver,

    /// Records, then yields a real event-loop turn: a channel that never
    /// goes live would otherwise spin on microtasks and starve [until].
    sleep: (duration) async {
      sleepLog.add(duration);
      await Future<void>.delayed(Duration.zero);
    },
    isProResolver: () => true,
  );

  void configure(Map<String, String> entries) {
    settingsBox().put(SettingsKeys.YouTubeApiKey.name, 'api-key');
    settingsBox().put(SettingsKeys.YouTubeUsernames.name, entries);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('youtube_rollover_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
    await Hive.openBox(HiveKeys.Settings.name);
    chatService = FakeYouTubeLiveChatService();
    resolver = FakeYouTubeLiveResolver();
    sleepLog = <Duration>[];
  });

  tearDown(() async {
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('channel entries load next to video entries', () async {
    configure({
      'Mine': '@MyChannel',
      'Id': 'UCSJ4gkVC6NrvII8umztf0Ow',
      'Video': 'video-a-001',
    });
    resolver = FakeYouTubeLiveResolver([null]);
    store = newStore();
    await store.init();

    final byLabel = {for (final c in store.channels) c.label: c};
    expect(byLabel['Mine']!.isChannel, isTrue);
    expect(byLabel['Mine']!.videoId, isNull);
    expect(
      (byLabel['Id']!.target as YouTubeChannelTarget).path,
      'channel/UCSJ4gkVC6NrvII8umztf0Ow',
    );
    expect(byLabel['Video']!.videoId, 'video-a-001');
  });

  test('a live channel resolves its stream and connects', () async {
    configure({'Mine': '@MyChannel'});
    resolver = FakeYouTubeLiveResolver(['stream-1']);
    chatService.liveChatIds['stream-1'] = 'chat-1';
    chatService.pollResponses.add(_page([_message('m1')], nextPageToken: 't1'));
    store = newStore();

    await store.init();
    await until(
      () => store.chatConnection == YouTubeChatConnectionState.connected,
    );

    expect(resolver.calls, ['@MyChannel']);
    expect(store.selectedLiveVideoId, 'stream-1');
    expect(store.awaitingLiveStream, isFalse);
    expect(store.messages.map((m) => m.id), ['m1']);
  });

  test('an offline channel keeps watching and connects once live', () async {
    configure({'Mine': '@MyChannel'});
    resolver = FakeYouTubeLiveResolver([null, null, 'stream-1']);
    chatService.liveChatIds['stream-1'] = 'chat-1';
    chatService.pollResponses.add(_page([_message('m1')]));
    store = newStore();

    await store.init();
    await until(
      () => store.chatConnection == YouTubeChatConnectionState.connected,
    );

    expect(resolver.calls.length, 3);
    expect(
      sleepLog.take(2),
      kYouTubeLiveRecheckSchedule.take(2),
      reason: 'rechecks follow the escalating schedule',
    );
    expect(chatService.resolveCalls, 1, reason: 'offline checks cost no quota');
    expect(store.awaitingLiveStream, isFalse);
  });

  test(
    'stream end rolls over to the next stream on the same channel',
    () async {
      configure({'Mine': '@MyChannel'});

      /// The `/live` page lags: it keeps pointing at the finished stream
      /// for one check before the next stream appears.
      resolver = FakeYouTubeLiveResolver([
        'stream-1',
        'stream-1',
        null,
        'stream-2',
      ]);
      chatService.liveChatIds['stream-1'] = 'chat-1';
      chatService.liveChatIds['stream-2'] = 'chat-2';
      chatService.pollResponses
        ..add(_page([_message('m1')], nextPageToken: 't1'))
        ..add(
          _page(
            [_message('m2')],
            nextPageToken: 't2',
            offlineAt: DateTime.utc(2026, 9, 24, 20),
          ),
        )
        ..add(_page([_message('n1')], nextPageToken: 'u1'));
      store = newStore();

      await store.init();
      await until(() => store.messages.any((m) => m.id == 'n1'));

      expect(store.chatConnection, YouTubeChatConnectionState.connected);
      expect(store.selectedLiveVideoId, 'stream-2');

      /// The finished stream's rows stay as history above the new stream.
      expect(store.messages.map((m) => m.id), ['m1', 'm2', 'n1']);

      /// New stream starts a fresh cursor; the lagging re-resolve of the
      /// ended stream never spent a `videos.list` unit.
      expect(chatService.listPageTokens.take(3), [null, 't1', null]);
      expect(chatService.resolveCalls, 2);
    },
  );

  test('chatEnded on a channel entry waits for the next stream', () async {
    configure({'Mine': '@MyChannel'});
    resolver = FakeYouTubeLiveResolver(['stream-1', null]);
    chatService.liveChatIds['stream-1'] = 'chat-1';
    chatService.pollResponses
      ..add(_page([_message('m1')]))
      ..add(const YouTubeChatEndedException('Listing chat failed'));
    store = newStore();

    await store.init();
    await until(() => store.awaitingLiveStream);

    expect(store.chatConnection, YouTubeChatConnectionState.offline);
    expect(store.chatError, isNull);
    expect(store.selectedLiveVideoId, isNull);
    expect(store.messages.map((m) => m.id), ['m1']);
  });

  test('video entries still stop at offline (no rollover)', () async {
    configure({'Video': 'video-a-001'});
    chatService.liveChatIds['video-a-001'] = 'chat-a';
    chatService.pollResponses.add(
      const YouTubeChatEndedException('Listing chat failed'),
    );
    store = newStore();

    await store.init();
    await until(
      () => store.chatConnection == YouTubeChatConnectionState.offline,
    );
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    expect(store.awaitingLiveStream, isFalse);
    expect(resolver.calls, isEmpty);
    expect(chatService.listCalls, 1);
  });

  test('a lookup failure keeps retrying and surfaces the reason', () async {
    configure({'Mine': '@MyChannel'});
    resolver = FakeYouTubeLiveResolver([
      const YouTubeLiveResolveException('Could not reach YouTube'),
    ]);
    store = newStore();

    await store.init();
    await until(() => resolver.calls.length >= 3);

    expect(store.chatConnection, YouTubeChatConnectionState.offline);
    expect(store.awaitingLiveStream, isTrue);
    expect(store.chatError, 'Could not reach YouTube');
  });

  test('an unknown channel (404) is a terminal error', () async {
    configure({'Mine': '@NoSuchChannel'});
    resolver = FakeYouTubeLiveResolver([
      const YouTubeLiveResolveException(
        'YouTube channel @NoSuchChannel not found',
        statusCode: 404,
      ),
    ]);
    store = newStore();

    await store.init();
    await until(() => store.chatConnection == YouTubeChatConnectionState.error);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    expect(resolver.calls.length, 1);
    expect(store.chatError, contains('not found'));
    expect(store.awaitingLiveStream, isFalse);
  });

  test('re-editing a channel entry to another channel retires it', () async {
    configure({'Mine': '@MyChannel'});
    resolver = FakeYouTubeLiveResolver(['stream-1']);
    chatService.liveChatIds['stream-1'] = 'chat-1';
    chatService.pollResponses.add(_page([_message('m1')]));
    store = newStore();
    await store.init();
    await until(() => store.messages.isNotEmpty);

    settingsBox().put(SettingsKeys.YouTubeUsernames.name, <String, String>{
      'Mine': '@OtherChannel',
    });
    store.reloadChannels();
    await until(() => resolver.calls.length >= 2);

    expect(store.messages, isEmpty);
    expect(resolver.calls.last, '@OtherChannel');
  });
}
