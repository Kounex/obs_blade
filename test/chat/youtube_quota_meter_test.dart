import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_quota_meter.dart';

/// What Settings → Logs says the app spent of the API key's quota
void main() {
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 10, 20, 13, 20);
    YouTubeQuotaMeter.reset();
    YouTubeQuotaMeter.now = () => now;
  });

  tearDown(() {
    YouTubeQuotaMeter.reset();
    YouTubeQuotaMeter.now = DateTime.now;
  });

  test('counts the chat service\'s calls at Google\'s costs', () async {
    final service = YouTubeLiveChatService(
      client: YouTubeMeteredClient(
        MockClient(
          (request) async => http.Response(
            request.url.path.endsWith('/videos')
                ? '{"items": []}'
                : '{"items": [], "pollingIntervalMillis": 2000}',
            200,
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await service.listMessages('chat-1', null, apiKey: 'key');
    }
    await service.resolveLiveStreamingDetails('video-1', apiKey: 'key');
    YouTubeQuotaMeter.record('liveChatMessages.streamList', 5);
    now = now.add(const Duration(minutes: 7));

    expect(
      YouTubeQuotaMeter.summary(),
      'YouTube API: ≈21 units in 7 min since 13:20 - '
      'liveChatMessages.list 3×5, liveChatMessages.streamList 1×5, '
      'videos.list 1×1',
    );
  });

  test('search has its own bucket; other hosts and unknown calls add no '
      'units', () {
    YouTubeQuotaMeter.recordRequest(
      http.Request(
        'GET',
        Uri.parse('https://www.googleapis.com/youtube/v3/search?q=x'),
      ),
    );
    YouTubeQuotaMeter.recordRequest(
      http.Request('GET', Uri.parse('https://www.youtube.com/live_chat')),
    );
    YouTubeQuotaMeter.recordRequest(
      http.Request(
        'GET',
        Uri.parse('https://www.googleapis.com/youtube/v3/playlists'),
      ),
    );
    expect(
      YouTubeQuotaMeter.summary(reason: 'quota used up'),
      'YouTube API (quota used up): ≈0 units in 0 min since 13:20 - '
      'search.list (own bucket) 1×0, GET playlists (cost unknown) 1×0',
    );
  });

  test('a line an hour: the call after the hour starts the next one', () {
    YouTubeQuotaMeter.record('liveChatMessages.list', 5);
    now = now.add(const Duration(minutes: 59));
    YouTubeQuotaMeter.record('liveChatMessages.list', 5);
    expect(YouTubeQuotaMeter.summary(), contains('list 2×5'));

    now = now.add(const Duration(minutes: 1));
    YouTubeQuotaMeter.record('liveChatMessages.list', 5);
    expect(
      YouTubeQuotaMeter.summary(),
      'YouTube API: ≈5 units in 0 min since 14:20 - '
      'liveChatMessages.list 1×5',
    );
  });

  test('nothing counted: no line', () {
    expect(YouTubeQuotaMeter.summary(), isNull);
    YouTubeQuotaMeter.logNow();
    expect(YouTubeQuotaMeter.summary(), isNull);
  });
}
