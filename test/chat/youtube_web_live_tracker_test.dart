import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_web_live_tracker.dart';

import 'support/fake_youtube_services.dart';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('resolves a channel to its live video id', () async {
    final tracker = YouTubeWebLiveTracker(
      resolver: FakeYouTubeLiveResolver(['stream-1']),
    );
    tracker.track(const YouTubeChannelTarget('@NASA'));
    await _settle();

    expect(tracker.state, YouTubeWebLiveState.live);
    expect(tracker.videoId, 'stream-1');
    tracker.dispose();
  });

  test('offline, then recheck picks up the new stream', () async {
    final resolver = FakeYouTubeLiveResolver([null, 'stream-2']);
    final tracker = YouTubeWebLiveTracker(resolver: resolver);
    tracker.track(const YouTubeChannelTarget('@NASA'));
    await _settle();
    expect(tracker.state, YouTubeWebLiveState.offline);
    expect(tracker.videoId, isNull);

    tracker.recheck();
    await _settle();
    expect(tracker.videoId, 'stream-2');
    tracker.dispose();
  });

  test('a lookup failure keeps a running embed', () async {
    final tracker = YouTubeWebLiveTracker(
      resolver: FakeYouTubeLiveResolver([
        'stream-1',
        const YouTubeLiveResolveException('Could not reach YouTube'),
      ]),
    );
    tracker.track(const YouTubeChannelTarget('@NASA'));
    await _settle();
    tracker.recheck();
    await _settle();

    expect(tracker.state, YouTubeWebLiveState.live);
    expect(tracker.videoId, 'stream-1');
    tracker.dispose();
  });

  test('same target is a no-op, null stops tracking', () async {
    final resolver = FakeYouTubeLiveResolver(['stream-1']);
    final tracker = YouTubeWebLiveTracker(resolver: resolver);
    tracker.track(const YouTubeChannelTarget('@NASA'));
    tracker.track(const YouTubeChannelTarget('@nasa'));
    await _settle();
    expect(resolver.calls.length, 1);

    tracker.track(null);
    expect(tracker.videoId, isNull);
    tracker.dispose();
  });
}
