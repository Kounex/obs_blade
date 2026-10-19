import 'dart:async';
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
import 'package:obs_blade/utils/youtube/youtube_live_chat_stream.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube_target.dart';

import '../chat/support/fake_youtube_services.dart' show FakeChatStream;

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

/// Holds the `/live` answer until [release]
class _GatedResolver extends YouTubeLiveResolver {
  String? answer;
  final _gate = Completer<void>();

  void release() => this._gate.complete();

  @override
  Future<String?> resolveLiveVideoId(YouTubeChannelTarget channel) async {
    await this._gate.future;
    return this.answer;
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

  /// Scripted `streamList` calls; none queued: the stream isn't served
  /// and the step polls (what the poll tests rely on)
  final Queue<FakeChatStream> streams = Queue();
  final List<String?> streamTokens = [];

  @override
  Stream<YouTubeLiveChatPage> streamMessages(
    String liveChatId,
    String? pageToken, {
    String? apiKey,
    String? accessToken,
    void Function()? onOpen,
  }) {
    this.streamTokens.add(pageToken);
    if (this.streams.isEmpty) {
      return Stream.error(
        const YouTubeStreamFallbackException('No stream scripted'),
      );
    }
    return this.streams.removeFirst().openForTest(onOpen);
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

/// A broadcast that has started (an upcoming one has no actualStartTime)
final _live = YouTubeLiveStreamingDetails(
  liveChatId: 'chat1',
  actualStartTime: DateTime.utc(2026, 10, 2, 19, 55),
);

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
    chat.details = _live;
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

  test('upcoming stream with a waiting-room chat: not live, checked '
      'every 5 min at most (1 unit each)', () async {
    resolver.answers.add('upcoming');
    chat.details = const YouTubeLiveStreamingDetails(liveChatId: 'waiting');
    poller.fast = true;
    expect(await poller.step(), const Duration(minutes: 5));
    expect(poller.state, YouTubeOwnActivityState.waiting);
    expect(chat.tokens, isEmpty);
  });

  test('turned off while a request is out: stays off', () async {
    final gate = _GatedResolver()..answer = 'vid1';
    final gated = YouTubeOwnActivityPoller(
      resolver: gate,
      chatService: chat,
      clock: () => now,
    )..enabledForTest(channelId: 'UCme', apiKey: 'key');
    chat.details = _live;
    final pending = gated.step();
    gated.configure(channelId: null, apiKey: 'key', enabled: true);
    gate.release();
    await pending;
    expect(gated.state, YouTubeOwnActivityState.off);
  });

  test(
    'chat ended: back to waiting, the ended video isn\'t re-attached',
    () async {
      resolver.answers.add('vid1');
      chat.details = _live;
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
    chat.details = _live;
    await poller.step();
    chat.pages.add(_page([_superChat('last')], offlineAt: now));
    await poller.step();
    expect(events.single.id, 'youtube:UCme:last');
    expect(poller.state, YouTubeOwnActivityState.waiting);
  });

  test('quota used up: stops until the reset, no calls meanwhile', () async {
    resolver.answers.add('vid1');
    chat.details = _live;
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
    chat.details = _live;
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
    chat.details = _live;
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
    chat.details = _live;
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

  group('stream (streamList)', () {
    /// Attached to the live chat, nothing read yet
    Future<void> attach() async {
      resolver.answers.add('vid1');
      chat.details = _live;
      await poller.step();
      expect(poller.state, YouTubeOwnActivityState.live);
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('reads over the stream, no poll: rows come out, the server '
        'closing a long call reconnects at once from the token', () async {
      await attach();
      final first = FakeChatStream();
      final second = FakeChatStream();
      chat.streams.addAll([first, second]);

      final step = poller.step();
      await settle();
      first.open();
      first.add(_page([_text('t1'), _superChat('s1')], token: 'p2'));
      await settle();
      expect(events.map((e) => e.id), ['youtube:UCme:s1']);
      now = now.add(const Duration(minutes: 20));
      await first.end();
      expect(await step, Duration.zero);

      final next = poller.step();
      await settle();
      expect(second.listened, isTrue);
      expect(chat.streamTokens, [null, 'p2']);
      second.open();
      await second.end();
      await next;
      expect(chat.tokens, isEmpty);
    });

    test(
      'a stream it can\'t use: the same step polls, and keeps polling',
      () async {
        await attach();
        chat.pages
          ..add(_page([_superChat('s1')], token: 'p2'))
          ..add(_page([_superChat('s2')], token: 'p3'));

        expect(await poller.step(), YouTubeOwnActivityPoller.pollInterval);
        expect(await poller.step(), YouTubeOwnActivityPoller.pollInterval);
        expect(chat.streamTokens, [null]);
        expect(chat.tokens, [null, 'p2']);
        expect(events.map((e) => e.id), ['youtube:UCme:s1', 'youtube:UCme:s2']);
      },
    );

    test('ended or disabled (FAILED_PRECONDITION): one poll asks - '
        'liveChatEnded ends it', () async {
      await attach();
      final call = FakeChatStream();
      chat.streams.add(call);
      chat.pages.add(const YouTubeChatEndedException('ended'));

      final step = poller.step();
      await settle();
      call.open();
      await call.fail(const YouTubeChatEndedException('stream: ended'));
      await step;

      expect(chat.tokens, [null]);
      expect(poller.state, YouTubeOwnActivityState.waiting);
    });

    test('ended or disabled, and the poll says the chat runs: back to the '
        'stream only after Google\'s interval (sooner, a call with the '
        'poll\'s token answers PERMISSION_DENIED)', () async {
      await attach();
      final call = FakeChatStream();
      chat.streams.add(call);
      chat.pages.add(_page([_text('t1')], token: 'p2', interval: 4000));

      final step = poller.step();
      await settle();
      call.open();
      await call.fail(const YouTubeChatEndedException('stream: disabled'));

      expect(await step, const Duration(milliseconds: 4000));
      expect(chat.tokens, [null]);
    });

    test('a chatEnded row on the stream ends the chat; the ended video '
        'isn\'t re-attached', () async {
      await attach();
      final call = FakeChatStream();
      chat.streams.add(call);

      final step = poller.step();
      await settle();
      call.open();
      call.add(
        _page([
          YouTubeChatMessage.fromJson({
            'id': 'end',
            'snippet': {
              'type': 'chatEndedEvent',
              'publishedAt': '2026-10-02T21:00:00Z',
            },
          }),
        ]),
      );
      await step;
      expect(poller.state, YouTubeOwnActivityState.waiting);

      await poller.step();
      expect(poller.state, YouTubeOwnActivityState.waiting);
      expect(chat.detailCalls, 1);
      expect(call.cancelled, isTrue);
    });

    test(
      'standby (the chat reads the own chat) closes the open call',
      () async {
        await attach();
        final call = FakeChatStream();
        chat.streams.add(call);

        final step = poller.step();
        await settle();
        call.open();
        poller.standby = true;
        expect(call.cancelled, isTrue);
        await step;
        await poller.step();
        expect(poller.state, YouTubeOwnActivityState.standby);
      },
    );

    test('back from the background: a new call from the token', () async {
      await attach();
      final before = FakeChatStream();
      final after = FakeChatStream();
      chat.streams.addAll([before, after]);

      final step = poller.step();
      await settle();
      before.open();
      before.add(_page([_superChat('s1')], token: 'p2'));
      await settle();
      poller.foreground = false;
      expect(before.cancelled, isFalse);
      poller.foreground = true;
      expect(before.cancelled, isTrue);
      expect(await step, Duration.zero);

      final next = poller.step();
      await settle();
      expect(chat.streamTokens, [null, 'p2']);
      after.open();
      await after.end();
      await next;
    });
  });

  test('a stream page token the poll refuses (400): starts over once '
      'without it', () async {
    resolver.answers.add('vid1');
    chat.details = _live;
    await poller.step();
    final call = FakeChatStream();
    chat.streams.add(call);

    final step = poller.step();
    await Future<void>.delayed(Duration.zero);
    call.open();
    call.add(_page([_superChat('s1')], token: 'stream-1'));
    await Future<void>.delayed(Duration.zero);
    await call.fail(const YouTubeStreamFallbackException('x'));
    chat.pages
      ..add(const YouTubeApiException('bad token', statusCode: 400))
      ..add(_page([_superChat('s1'), _superChat('s2')], token: 'p2'));
    expect(await step, Duration.zero);
    await poller.step();

    expect(chat.tokens, ['stream-1', null]);
    expect(events.map((e) => e.id).toSet(), {
      'youtube:UCme:s1',
      'youtube:UCme:s2',
    });
    expect(poller.state, YouTubeOwnActivityState.live);
  });

  for (final (name, act) in [
    (
      'turned off',
      (YouTubeOwnActivityPoller p) =>
          p.configure(channelId: 'UCme', apiKey: 'key', enabled: false),
    ),
    (
      'another channel',
      (YouTubeOwnActivityPoller p) =>
          p.configure(channelId: 'UCother', apiKey: 'key', enabled: true),
    ),
  ]) {
    test('$name while a stream step waits: the call closes, nothing of the '
        'old chat comes back', () async {
      resolver.answers.add('vid1');
      chat.details = _live;
      await poller.step();
      final call = FakeChatStream();
      chat.streams.add(call);

      final step = poller.step();
      await Future<void>.delayed(Duration.zero);
      call.open();
      act(poller);
      expect(call.cancelled, isTrue);
      expect(await step, Duration.zero);

      /// The next step (at once) is about the new state, never the old chat
      resolver.answers
        ..clear()
        ..add(null);
      await poller.step();
      expect(poller.state, isNot(YouTubeOwnActivityState.live));
      expect(chat.tokens, isEmpty);
      expect(chat.streamTokens, [null]);
    });
  }

  test('a 403 that stays (not a switched-off chat): the wait doubles, the '
      'feed doesn\'t flap every 5 min', () async {
    resolver.answers.add('vid1');
    chat.details = _live;
    final waits = <Duration>[];
    for (var i = 0; i < 3; i++) {
      await poller.step();
      expect(poller.state, YouTubeOwnActivityState.live);
      chat.pages.add(
        const YouTubeForbiddenException('forbidden', statusCode: 403),
      );
      waits.add(await poller.step());
    }
    expect(waits, [
      const Duration(minutes: 5),
      const Duration(minutes: 10),
      const Duration(minutes: 20),
    ]);
  });

  test('a 403 that isn\'t "ended" (chat turned off): waits and looks '
      'again, not "ended for good"', () async {
    resolver.answers.add('vid1');
    chat.details = _live;
    await poller.step();
    chat.pages.add(
      const YouTubeForbiddenException('liveChatDisabled', statusCode: 403),
    );

    expect(await poller.step(), const Duration(minutes: 5));
    expect(poller.state, YouTubeOwnActivityState.waiting);

    /// Switched back on: the next look attaches to the same video
    await poller.step();
    expect(chat.detailCalls, 2);
    expect(poller.state, YouTubeOwnActivityState.live);
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
