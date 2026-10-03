import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/activity.dart';
import 'package:obs_blade/utils/activity/activity_persistence.dart';
import 'package:obs_blade/utils/activity/obs_stream_destination.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/utils/activity/youtube_own_activity_poller.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube_target.dart';

/// `/live` page check: a queue of answers (video id, null = not live, or
/// an exception to throw); the last one repeats.
class _Resolver extends YouTubeLiveResolver {
  final Queue<Object?> answers = Queue();
  final List<String> paths = [];

  @override
  Future<String?> resolveLiveVideoId(YouTubeChannelTarget channel) async {
    this.paths.add(channel.path);
    final answer = this.answers.length > 1
        ? this.answers.removeFirst()
        : this.answers.firstOrNull;
    if (answer is Exception) throw answer;
    return answer as String?;
  }
}

class _Chat extends YouTubeLiveChatService {
  YouTubeLiveStreamingDetails details = const YouTubeLiveStreamingDetails();
  Object? resolveThrows;

  /// Pages (or exceptions) in order
  final Queue<Object> pages = Queue();
  final List<String?> tokens = [];
  int detailCalls = 0;

  @override
  Future<YouTubeLiveStreamingDetails> resolveLiveStreamingDetails(
    String videoId, {
    String? apiKey,
    String? accessToken,
  }) async {
    this.detailCalls++;
    if (this.resolveThrows != null) throw this.resolveThrows!;
    return this.details;
  }

  @override
  Future<YouTubeLiveChatPage> listMessages(
    String liveChatId,
    String? pageToken, {
    String? apiKey,
    String? accessToken,
  }) async {
    this.tokens.add(pageToken);
    final next = this.pages.removeFirst();
    if (next is Exception) throw next;
    return next as YouTubeLiveChatPage;
  }
}

class _NoRelay extends KickEventsRelayClient {
  @override
  Future<void> stop() async {}
}

YouTubeChatMessage _superChat(String id) => YouTubeChatMessage.fromJson({
  'id': id,
  'snippet': {
    'type': 'superChatEvent',
    'publishedAt': '2026-10-02T20:00:00Z',
    'authorChannelId': 'UCfan',
    'superChatDetails': {
      'amountMicros': '5000000',
      'currency': 'USD',
      'amountDisplayString': r'$5.00',
    },
  },
  'authorDetails': {'channelId': 'UCfan', 'displayName': 'Fan'},
});

YouTubeChatMessage _text(String id) => YouTubeChatMessage.fromJson({
  'id': id,
  'snippet': {
    'type': 'textMessageEvent',
    'publishedAt': '2026-10-02T20:00:00Z',
    'authorChannelId': 'UCfan',
    'textMessageDetails': {'messageText': 'hi'},
  },
  'authorDetails': {'channelId': 'UCfan', 'displayName': 'Fan'},
});

YouTubeLiveChatPage _page(
  List<YouTubeChatMessage> messages, {
  String? token,
  int interval = 3000,
  DateTime? offlineAt,
}) => YouTubeLiveChatPage(
  messages: messages,
  nextPageToken: token,
  pollingIntervalMillis: interval,
  offlineAt: offlineAt,
);

void main() {
  late _Resolver resolver;
  late _Chat chat;
  late DateTime now;
  late YouTubeOwnActivityPoller poller;
  late List<ActivityEvent> events;

  setUp(() {
    resolver = _Resolver();
    chat = _Chat();
    now = DateTime.utc(2026, 10, 2, 20);
    events = [];
    poller =
        YouTubeOwnActivityPoller(
            resolver: resolver,
            chatService: chat,
            clock: () => now,
          )
          ..onEvent = events.add
          ..enabledForTest(channelId: 'UCme', apiKey: 'key');
  });

  test('not live: quota-free check only, slower without OBS', () async {
    resolver.answers.add(null);
    expect(await poller.step(), YouTubeOwnActivityPoller.idleCheck);
    expect(poller.state, YouTubeOwnActivityState.waiting);
    expect(resolver.paths, ['channel/UCme']);
    expect(chat.detailCalls, 0);

    poller.fast = true;
    expect(await poller.step(), YouTubeOwnActivityPoller.fastCheck);
  });

  test('in the background a waiting poller doesn\'t check', () async {
    resolver.answers.add('vid1');
    poller.foreground = false;
    await poller.step();
    expect(resolver.paths, isEmpty);

    /// ...unless OBS streams
    poller.fast = true;
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.live);
  });

  test('live: attaches once, then polls every 30 s with the page token, '
      'only activity rows come out', () async {
    resolver.answers.add('vid1');
    chat.details = YouTubeLiveStreamingDetails(
      liveChatId: 'chat1',
      actualStartTime: DateTime.utc(2026, 10, 2, 19, 30),
    );
    expect(await poller.step(), Duration.zero);
    expect(poller.state, YouTubeOwnActivityState.live);
    expect(poller.liveSince, DateTime.utc(2026, 10, 2, 19, 30));

    chat.pages
      ..add(_page([_text('t1'), _superChat('s1')], token: 'p2'))
      ..add(_page([_superChat('s2')], token: 'p3', interval: 45000));
    expect(await poller.step(), YouTubeOwnActivityPoller.pollInterval);
    expect(await poller.step(), const Duration(seconds: 45));
    expect(chat.tokens, [null, 'p2']);
    expect(events.map((e) => e.id), ['youtube:UCme:s1', 'youtube:UCme:s2']);
    expect(chat.detailCalls, 1);
  });

  test('scheduled stream without a chat yet: keeps waiting', () async {
    resolver.answers.add('upcoming');
    chat.details = const YouTubeLiveStreamingDetails();
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.waiting);
  });

  test(
    'chat ended: back to waiting, the ended video isn\'t re-attached',
    () async {
      resolver.answers.add('vid1');
      chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
      await poller.step();
      chat.pages.add(const YouTubeChatEndedException('ended'));
      await poller.step();
      expect(poller.state, YouTubeOwnActivityState.waiting);

      /// `/live` still points at the finished stream for a while
      await poller.step();
      expect(poller.state, YouTubeOwnActivityState.waiting);
      expect(chat.detailCalls, 1);
    },
  );

  test('offlineAt on a page ends the chat after its rows', () async {
    resolver.answers.add('vid1');
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
    await poller.step();
    chat.pages.add(_page([_superChat('last')], offlineAt: now));
    await poller.step();
    expect(events.single.id, 'youtube:UCme:last');
    expect(poller.state, YouTubeOwnActivityState.waiting);
  });

  test('quota used up: stops until the reset, no calls meanwhile', () async {
    resolver.answers.add('vid1');
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
    await poller.step();
    chat.pages.add(const YouTubeQuotaExceededException('quota'));
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.quotaExhausted);
    final resetAt = poller.quotaResetAt!;
    expect(resetAt.isAfter(now), isTrue);

    now = now.add(const Duration(hours: 1));
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.quotaExhausted);
    expect(resolver.paths, hasLength(1));

    now = resetAt.add(const Duration(seconds: 1));
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.live);
  });

  test('throttled or offline network: backs off, keeps the chat', () async {
    resolver.answers.add('vid1');
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
    await poller.step();
    chat.pages
      ..add(const YouTubeRateLimitedException('slow down'))
      ..add(const YouTubeApiException('offline'))
      ..add(_page([_superChat('s1')], token: 'p2'));
    expect(await poller.step(), const Duration(seconds: 30));
    expect(await poller.step(), const Duration(seconds: 60));
    await poller.step();
    expect(events.single.id, 'youtube:UCme:s1');
    expect(poller.state, YouTubeOwnActivityState.live);
  });

  test('standby while the YouTube chat reads the own chat', () async {
    resolver.answers.add('vid1');
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
    await poller.step();
    poller.standby = true;
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.standby);
    expect(chat.tokens, isEmpty);

    /// The chat moved to another channel: re-attach and read again
    poller.standby = false;
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.live);
  });

  test('a failed live check is not "offline forever"', () async {
    resolver.answers
      ..add(const YouTubeLiveResolveException('consent wall'))
      ..add('vid1');
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'chat1');
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.waiting);
    await poller.step();
    expect(poller.state, YouTubeOwnActivityState.live);
  });

  test('without channel or key it is off', () async {
    poller.configure(channelId: null, apiKey: 'key', enabled: true);
    expect(poller.state, YouTubeOwnActivityState.off);
    poller.configure(channelId: 'UCme', apiKey: '', enabled: true);
    expect(poller.state, YouTubeOwnActivityState.off);
  });

  group('in the activity store', () {
    late ActivityStore store;

    setUp(() async {
      store = ActivityStore(
        persistence: MemoryActivityPersistence(),
        isProResolver: () => true,
        clock: () => now,
        relayClient: _NoRelay(),
        relayEnabledResolver: () => true,
        youTubePoller: poller,
        attachPlatformStores: false,
      );
      await store.init();
    });

    tearDown(() => store.dispose());

    test(
      'own stream live: session from its start, listened, rows land',
      () async {
        resolver.answers.add('vid1');
        chat.details = YouTubeLiveStreamingDetails(
          liveChatId: 'chat1',
          actualStartTime: DateTime.utc(2026, 10, 2, 19, 59, 30),
        );
        await poller.step();
        expect(store.youTubeOwnState, YouTubeOwnActivityState.live);
        final session = store.currentSession!;
        expect(session.platforms, {ActivityPlatform.youtube});
        expect(session.start, DateTime.utc(2026, 10, 2, 19, 59, 30));

        chat.pages.add(_page([_superChat('s1')]));
        await poller.step();
        expect(store.allEvents.single.id, 'youtube:UCme:s1');

        /// 30 s before the app attached is under the 1-minute gap floor
        expect(store.gapsOf(session), isEmpty);

        chat.pages.add(const YouTubeChatEndedException('ended'));
        await poller.step();
        expect(store.liveSources, isNot(contains('youtube-own')));
      },
    );

    test('quota used up shows on the store', () async {
      resolver.answers.add('vid1');
      chat.resolveThrows = const YouTubeQuotaExceededException('quota');
      await poller.step();
      expect(store.youTubeOwnState, YouTubeOwnActivityState.quotaExhausted);
      expect(store.youTubeQuotaResetAt, isNotNull);
    });
  });

  test('OBS stream destination from the service settings', () {
    Map<String, dynamic> common(String service) => {
      'streamServiceType': 'rtmp_common',
      'streamServiceSettings': {
        'service': service,
        'server': 'auto',
        'key': 'secret',
      },
    };
    Map<String, dynamic> custom(String server) => {
      'streamServiceType': 'rtmp_custom',
      'streamServiceSettings': {'server': server, 'key': 'secret'},
    };
    expect(
      obsStreamPlatform(common('YouTube - RTMPS')),
      ActivityPlatform.youtube,
    );
    expect(
      obsStreamPlatform(common('YouTube - HLS')),
      ActivityPlatform.youtube,
    );
    expect(obsStreamPlatform(common('Twitch')), ActivityPlatform.twitch);
    expect(obsStreamPlatform(common('Restream.io')), isNull);
    expect(
      obsStreamPlatform(custom('rtmp://a.rtmp.youtube.com/live2')),
      ActivityPlatform.youtube,
    );
    expect(
      obsStreamPlatform(custom('rtmp://live.twitch.tv/app')),
      ActivityPlatform.twitch,
    );
    expect(
      obsStreamPlatform(
        custom('rtmps://fa723fc1b171.global-contribute.live-video.net/app'),
      ),
      isNull,
    );
    expect(obsStreamPlatform(null), isNull);
    expect(obsStreamPlatform({'streamServiceType': 'whip_custom'}), isNull);
  });
}
