import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube/youtube_live_status_service.dart';

import 'support/fake_youtube_services.dart';

/// `videos.list?part=liveStreamingDetails` as YouTube answers it: a
/// scheduled stream has no `actualStartTime`, an ended one an
/// `actualEndTime`, a hidden count no `concurrentViewers` (a string)
http.Response videosAnswer(Map<String, Map<String, Object?>> details) =>
    http.Response(
      json.encode({
        'items': [
          for (final entry in details.entries)
            {'id': entry.key, 'liveStreamingDetails': entry.value},
        ],
      }),
      200,
    );

const Map<String, Object?> kLive = {
  'actualStartTime': '2026-10-04T10:00:00Z',
  'concurrentViewers': '1234',
};

void main() {
  late List<Uri> requests;

  YouTubeLiveStatusService service(
    KeyedLiveResolver resolver,
    Map<String, Map<String, Object?>> details, {
    DateTime Function()? now,
    int status = 200,
  }) => YouTubeLiveStatusService(
    resolver: resolver,
    client: MockClient((request) async {
      requests.add(request.url);
      return status == 200
          ? videosAnswer(details)
          : http.Response('{}', status);
    }),
    now: now,
  );

  setUp(() => requests = []);

  test('live with viewers, scheduled / ended / offline not live, a hidden '
      'count is live without viewers - one videos.list for the lot', () async {
    final resolver = KeyedLiveResolver({
      'channel/UClive': 'vLive',
      'channel/UCscheduled': 'vScheduled',
      'channel/UCended': 'vEnded',
      'channel/UChidden': 'vHidden',
      'channel/UCoffline': null,
    });
    final s = service(resolver, {
      'vLive': kLive,
      'vScheduled': {'scheduledStartTime': '2026-10-05T10:00:00Z'},
      'vEnded': {...kLive, 'actualEndTime': '2026-10-04T11:00:00Z'},
      'vHidden': {'actualStartTime': '2026-10-04T10:00:00Z'},
    });
    final got = <String, YouTubeLiveStatus>{};
    final progress = <(int, int)>[];
    await s.check(
      ['UClive', 'UCscheduled', 'UCended', 'UChidden', 'UCoffline'],
      apiKey: 'key',
      onUpdate: got.addAll,
      onProgress: (done, total) => progress.add((done, total)),
    );
    expect(progress, [(0, 5), (5, 5)]);

    expect(got, {
      'UClive': (live: true, viewers: 1234),
      'UCscheduled': (live: false, viewers: null),
      'UCended': (live: false, viewers: null),
      'UChidden': (live: true, viewers: null),
      'UCoffline': (live: false, viewers: null),
    });
    expect(requests, hasLength(1));
    expect(requests.single.queryParameters['id']!.split(',').toSet(), {
      'vLive',
      'vScheduled',
      'vEnded',
      'vHidden',
    });
    expect(requests.single.queryParameters['part'], 'liveStreamingDetails');
  });

  test('a failed /live read or videos.list leaves the channel unknown and '
      'uncached', () async {
    final resolver = KeyedLiveResolver({
      'channel/UCbroken': const YouTubeLiveResolveException('boom'),
      'channel/UClive': 'vLive',
    });
    final s = service(resolver, {'vLive': kLive}, status: 403);
    final got = <String, YouTubeLiveStatus>{};
    await s.check(['UCbroken', 'UClive'], apiKey: 'key', onUpdate: got.addAll);

    expect(got, isEmpty);
    expect(s.cached('UCbroken'), isNull);
    expect(s.cached('UClive'), isNull);
  });

  test('answers are remembered for a minute', () async {
    var now = DateTime(2026, 10, 4, 12);
    final resolver = KeyedLiveResolver({'channel/UClive': 'vLive'});
    final s = service(resolver, {'vLive': kLive}, now: () => now);
    await s.check(['UClive'], apiKey: 'key', onUpdate: (_) {});

    final again = <String, YouTubeLiveStatus>{};
    await s.check(['UClive'], apiKey: 'key', onUpdate: again.addAll);
    expect(again, {'UClive': (live: true, viewers: 1234)});
    expect(resolver.calls, hasLength(1));

    now = now.add(const Duration(minutes: 2));
    await s.check(['UClive'], apiKey: 'key', onUpdate: (_) {});
    expect(resolver.calls, hasLength(2));
  });

  test('a long list goes in chunks and stops once cancelled', () async {
    final ids = [
      for (var i = 0; i < YouTubeLiveStatusService.chunkSize * 3; i++) 'UC$i',
    ];
    final resolver = KeyedLiveResolver({});
    final s = service(resolver, {});
    var updates = 0;
    await s.check(
      ids,
      apiKey: 'key',
      onUpdate: (_) => updates++,
      cancelled: () => updates >= 1,
    );

    expect(updates, 1);
    expect(resolver.calls, hasLength(YouTubeLiveStatusService.chunkSize));
  });

  test('no API key: videos.list reads with the sign-in token; with neither '
      'nothing is read', () async {
    final resolver = KeyedLiveResolver({'channel/UClive': 'vLive'});
    final headers = <Map<String, String>>[];
    final s = YouTubeLiveStatusService(
      resolver: resolver,
      client: MockClient((request) async {
        requests.add(request.url);
        headers.add(request.headers);
        return videosAnswer({'vLive': kLive});
      }),
    );

    await s.check(['UClive'], apiKey: '', onUpdate: (_) {});
    expect(resolver.calls, isEmpty);
    expect(requests, isEmpty);

    final got = <String, YouTubeLiveStatus>{};
    await s.check(
      ['UClive'],
      apiKey: '',
      accessToken: () async => 'token',
      onUpdate: got.addAll,
    );
    expect(got, {'UClive': (live: true, viewers: 1234)});
    expect(requests.single.queryParameters.containsKey('key'), isFalse);
    expect(headers.single['Authorization'], 'Bearer token');
  });
}
