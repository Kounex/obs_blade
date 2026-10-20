import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_stream.dart';
import 'package:obs_blade/utils/youtube/youtube_stream_policy.dart';

/// The YouTube chat's stream-or-poll rules.
void main() {
  late DateTime now;
  late YouTubeStreamPolicy policy;

  setUp(() {
    now = DateTime.utc(2026, 10, 19, 18);
    policy = YouTubeStreamPolicy(now: () => now);
  });

  const dropped = YouTubeStreamDroppedException('dropped');

  /// A call that opened and lived [lifetime] from its start, ended with
  /// [error]
  YouTubeStreamDecision lived(Duration lifetime, {Object? error}) {
    final startedAt = now;
    now = now.add(lifetime);
    return policy.callEnded(startedAt: startedAt, opened: true, error: error);
  }

  YouTubeStreamDecision neverOpened() =>
      policy.callEnded(startedAt: now, opened: false, error: dropped);

  test('streams until told otherwise', () {
    expect(policy.shouldStream, isTrue);
  });

  test('a long call (closed or dropped) reconnects at once, nothing shown', () {
    for (final error in [null, dropped]) {
      final decision = lived(const Duration(minutes: 5), error: error);
      expect(decision.next, YouTubeStreamNext.reconnect);
      expect(decision.delay, Duration.zero);
      expect(decision.dropped, isFalse);
    }
  });

  test('Google\'s ~10 s calls reconnect at once, however many in a row', () {
    for (var i = 0; i < 10; i++) {
      final decision = lived(const Duration(milliseconds: 10300));
      expect(decision.next, YouTubeStreamNext.reconnect);
      expect(decision.delay, Duration.zero);
    }
    expect(policy.shouldStream, isTrue);
  });

  test('short calls back off; the third in a row polls for 10 min', () {
    final first = lived(const Duration(seconds: 3));
    final second = lived(const Duration(seconds: 3), error: dropped);
    expect(
      [first.delay, second.delay],
      [const Duration(seconds: 1), const Duration(seconds: 2)],
    );
    expect(first.dropped, isFalse);
    expect(second.dropped, isTrue);

    final third = lived(const Duration(seconds: 3));
    expect(third.next, YouTubeStreamNext.poll);
    expect(policy.shouldStream, isFalse);
    now = now.add(kYouTubeStreamRetryAfter);
    expect(policy.shouldStream, isTrue);
  });

  test('a long call between short ones resets the count', () {
    lived(const Duration(seconds: 3));
    lived(const Duration(seconds: 3));
    lived(const Duration(minutes: 2));
    expect(lived(const Duration(seconds: 3)).next, YouTubeStreamNext.reconnect);
  });

  test('calls that never open: back off with "reconnecting", then one poll '
      'checks and the stream comes back after its answer', () {
    final a = neverOpened();
    final b = neverOpened();
    expect(
      [a.delay, b.delay],
      [const Duration(seconds: 1), const Duration(seconds: 2)],
    );
    expect(a.dropped && b.dropped, isTrue);

    expect(neverOpened().next, YouTubeStreamNext.poll);

    /// The probe: one poll, then streaming again at once
    expect(policy.shouldStream, isTrue);
  });

  test('a dead zone: the probe poll gets no answer, the stream opens '
      'later - no 10 min of polling', () {
    neverOpened();
    neverOpened();
    neverOpened();

    /// The poll failed too (no pollAnswered); the stream then opens
    lived(const Duration(minutes: 3));
    neverOpened();
    neverOpened();
    expect(neverOpened().next, YouTubeStreamNext.poll);
    expect(policy.shouldStream, isTrue);
  });

  test('gRPC blocked: the poll works while calls still never open → '
      'polls for 10 min', () {
    neverOpened();
    neverOpened();
    neverOpened();
    policy.pollAnswered();

    neverOpened();
    neverOpened();
    expect(neverOpened().next, YouTubeStreamNext.poll);
    expect(policy.shouldStream, isFalse);
    expect(policy.pollUntil, now.add(kYouTubeStreamRetryAfter));
  });

  test('FAILED_PRECONDITION (ended or disabled): one poll asks', () {
    final decision = policy.callEnded(
      startedAt: now,
      opened: true,
      error: const YouTubeChatEndedException('ended'),
    );
    expect(decision.next, YouTubeStreamNext.poll);
    expect(policy.shouldStream, isTrue);
  });

  test('any other refusal: the poll explains it for 10 min', () {
    final decision = policy.callEnded(
      startedAt: now,
      opened: false,
      error: const YouTubeStreamFallbackException('RESOURCE_EXHAUSTED'),
    );
    expect(decision.next, YouTubeStreamNext.poll);
    expect(policy.shouldStream, isFalse);
  });

  test('newRead (a restarted loop) isn\'t held to the short calls before '
      'it', () {
    lived(const Duration(seconds: 3));
    lived(const Duration(seconds: 3));
    policy.newRead();
    final next = lived(const Duration(seconds: 3));
    expect(next.next, YouTubeStreamNext.reconnect);
    expect(next.delay, const Duration(seconds: 1));
  });

  test('FAILED_PRECONDITION again after the check poll answered (the chat '
      'runs): polls for 10 min instead of ping-ponging', () {
    const ended = YouTubeChatEndedException('ended');
    policy.callEnded(startedAt: now, opened: true, error: ended);
    expect(policy.shouldStream, isTrue);
    policy.pollAnswered();

    expect(
      policy.callEnded(startedAt: now, opened: true, error: ended).next,
      YouTubeStreamNext.poll,
    );
    expect(policy.shouldStream, isFalse);
  });

  test('two dead-zone probes in a row without a poll answer stay probes', () {
    for (var round = 0; round < 2; round++) {
      neverOpened();
      neverOpened();
      expect(neverOpened().next, YouTubeStreamNext.poll);
      expect(policy.shouldStream, isTrue, reason: 'round $round');
    }
  });

  test('the reconnect wait is capped at 60 s, however calls interleave', () {
    final delays = <Duration>[];
    for (var i = 0; i < 12; i++) {
      final decision = i.isEven
          ? lived(const Duration(seconds: 3), error: dropped)
          : neverOpened();
      if (decision.next == YouTubeStreamNext.reconnect) {
        delays.add(decision.delay);
      }
    }
    expect(delays, isNotEmpty);
    expect(delays.every((d) => d <= kYouTubeStreamMaxReconnectDelay), isTrue);
  });

  test('reset (new chat / ended) clears the poll window', () {
    policy.callEnded(
      startedAt: now,
      opened: false,
      error: const YouTubeStreamFallbackException('x'),
    );
    expect(policy.shouldStream, isFalse);
    policy.reset();
    expect(policy.shouldStream, isTrue);
  });
}
