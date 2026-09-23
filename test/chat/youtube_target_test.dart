import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:obs_blade/utils/youtube/youtube_live_resolver.dart';
import 'package:obs_blade/utils/youtube_target.dart';

String? channelPath(String input) {
  final target = parseYouTubeTarget(input);
  return target is YouTubeChannelTarget ? target.path : null;
}

String? videoId(String input) {
  final target = parseYouTubeTarget(input);
  return target is YouTubeVideoTarget ? target.videoId : null;
}

/// Streams [body] in small chunks, recording how much was pulled.
class _ChunkedClient extends http.BaseClient {
  final int statusCode;
  final String body;
  final int chunkSize;
  int bytesServed = 0;
  http.BaseRequest? lastRequest;

  _ChunkedClient(this.body, {this.statusCode = 200, this.chunkSize = 256});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.lastRequest = request;
    final bytes = utf8.encode(this.body);
    Stream<List<int>> chunks() async* {
      for (var i = 0; i < bytes.length; i += this.chunkSize) {
        final end = i + this.chunkSize > bytes.length
            ? bytes.length
            : i + this.chunkSize;
        this.bytesServed = end;
        yield bytes.sublist(i, end);
      }
    }

    return http.StreamedResponse(chunks(), this.statusCode);
  }
}

const _livePage =
    '<!DOCTYPE html><html><head><title>NASA - YouTube</title>'
    '<link rel="alternate" href="android-app://x">'
    '<link rel="canonical" href="https://www.youtube.com/watch?v=M3HKLzjvKPc">'
    '<meta property="og:url" content="https://www.youtube.com/watch?v=M3HKLzjvKPc">';

const _offlinePage =
    '<html><head>'
    '<link rel="canonical" href="https://www.youtube.com/@mkbhd/live">';

void main() {
  group('parseYouTubeTarget - channels', () {
    test('@handle', () {
      expect(channelPath('@LofiGirl'), '@LofiGirl');
      expect(channelPath('  @lofi.girl-2  '), '@lofi.girl-2');
    });

    test('bare UC channel id', () {
      expect(
        channelPath('UCSJ4gkVC6NrvII8umztf0Ow'),
        'channel/UCSJ4gkVC6NrvII8umztf0Ow',
      );
    });

    test('channel URLs in every shape', () {
      expect(channelPath('https://www.youtube.com/@NASA'), '@NASA');
      expect(channelPath('https://m.youtube.com/@NASA/live'), '@NASA');
      expect(channelPath('youtube.com/@NASA/streams'), '@NASA');
      expect(
        channelPath(
          'https://www.youtube.com/channel/UCLA_DiR1FfKNvjuUpBHmylQ/live',
        ),
        'channel/UCLA_DiR1FfKNvjuUpBHmylQ',
      );
      expect(channelPath('https://www.youtube.com/c/LofiGirl'), 'c/LofiGirl');
      expect(
        channelPath('https://youtube.com/user/NASAtelevision/live'),
        'user/NASAtelevision',
      );
    });

    test('a v= query always means a video', () {
      expect(
        videoId('https://www.youtube.com/@NASA/live?v=M3HKLzjvKPc'),
        'M3HKLzjvKPc',
      );
    });

    test('non-YouTube hosts are not channels', () {
      expect(channelPath('https://twitch.tv/@someone'), isNull);
    });

    test('storageValue normalizes', () {
      expect(
        parseYouTubeTarget('https://youtube.com/@NASA')!.storageValue,
        '@NASA',
      );
      expect(
        parseYouTubeTarget(
          'https://youtube.com/channel/UCLA_DiR1FfKNvjuUpBHmylQ',
        )!.storageValue,
        'UCLA_DiR1FfKNvjuUpBHmylQ',
      );
      expect(
        parseYouTubeTarget('youtube.com/c/LofiGirl')!.storageValue,
        'c/LofiGirl',
      );

      /// The stored value parses back to the same target.
      for (final input in [
        '@NASA',
        'UCLA_DiR1FfKNvjuUpBHmylQ',
        'c/LofiGirl',
        'user/NASAtelevision',
      ]) {
        final target = parseYouTubeTarget(input)!;
        expect(parseYouTubeTarget(target.storageValue), target);
      }
    });

    test('handle keys are case-insensitive', () {
      expect(
        parseYouTubeTarget('@NASA')!.key,
        parseYouTubeTarget('https://youtube.com/@nasa')!.key,
      );
    });
  });

  group('parseYouTubeTarget - videos (legacy entries keep working)', () {
    test('bare id + watch / live / short / chat links', () {
      expect(videoId('m-i_0DcfF1s'), 'm-i_0DcfF1s');
      expect(
        videoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        videoId('https://www.youtube.com/live/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(videoId('https://youtu.be/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
      expect(
        videoId('https://www.youtube.com/live_chat?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('garbage / empty', () {
      expect(parseYouTubeTarget(null), isNull);
      expect(parseYouTubeTarget(''), isNull);
      expect(parseYouTubeTarget('not a thing'), isNull);
    });
  });

  group('parseLiveVideoIdFromChannelPage', () {
    test('live page → watch id', () {
      expect(parseLiveVideoIdFromChannelPage(_livePage), 'M3HKLzjvKPc');
    });

    test('offline page → null', () {
      expect(parseLiveVideoIdFromChannelPage(_offlinePage), isNull);
    });

    test('attribute order / quoting / &amp; tolerant', () {
      expect(
        parseLiveVideoIdFromChannelPage(
          "<link href='https://www.youtube.com/watch?feature=x&amp;v=abcdefghijk' rel='canonical'/>",
        ),
        'abcdefghijk',
      );
    });

    test('no canonical at all is unknown, not offline', () {
      expect(
        () => parseLiveVideoIdFromChannelPage('<html>consent</html>'),
        throwsA(isA<YouTubeLiveResolveException>()),
      );
    });
  });

  group('YouTubeLiveResolver', () {
    test('requests the channel /live page with consent cookies', () async {
      final client = _ChunkedClient(_livePage);
      final id = await YouTubeLiveResolver(
        client: client,
      ).resolveLiveVideoId(const YouTubeChannelTarget('@NASA'));

      expect(id, 'M3HKLzjvKPc');
      expect(
        client.lastRequest!.url.toString(),
        'https://www.youtube.com/@NASA/live',
      );
      expect(client.lastRequest!.headers['Cookie'], contains('SOCS='));
    });

    test('finds a canonical tag deep in a large page', () async {
      /// The desktop variant carries it ~700 KB in — no fixed scan cap.
      final page =
          '<html><head>${'<script>x</script>' * 45000}'
          '<link rel="canonical" href="https://www.youtube.com/watch?v=M3HKLzjvKPc">'
          '</head><body>';
      final id = await YouTubeLiveResolver(
        client: _ChunkedClient(page, chunkSize: 4000),
      ).resolveLiveVideoId(const YouTubeChannelTarget('@NASA'));
      expect(id, 'M3HKLzjvKPc');
    });

    test('a tag split across chunks is still found', () async {
      final id = await YouTubeLiveResolver(
        client: _ChunkedClient(_livePage, chunkSize: 7),
      ).resolveLiveVideoId(const YouTubeChannelTarget('@NASA'));
      expect(id, 'M3HKLzjvKPc');
    });

    test('finds a canonical tag emitted after </head>', () async {
      /// Offline channel pages put it in the body.
      final id = await YouTubeLiveResolver(
        client: _ChunkedClient(
          '<html><head></head><body>${'z' * 20000}$_offlinePage',
          chunkSize: 1024,
        ),
      ).resolveLiveVideoId(const YouTubeChannelTarget('@mkbhd'));
      expect(id, isNull);
    });

    test('stops reading once the canonical tag is in', () async {
      final client = _ChunkedClient(
        _livePage + ('x' * 400000),
        chunkSize: 1024,
      );
      await YouTubeLiveResolver(
        client: client,
      ).resolveLiveVideoId(const YouTubeChannelTarget('@NASA'));

      expect(client.bytesServed, lessThan(4096));
    });

    test('offline channel → null', () async {
      final id = await YouTubeLiveResolver(
        client: _ChunkedClient(_offlinePage),
      ).resolveLiveVideoId(const YouTubeChannelTarget('@mkbhd'));
      expect(id, isNull);
    });

    test('404 → not-found exception with status', () async {
      await expectLater(
        YouTubeLiveResolver(
          client: _ChunkedClient('', statusCode: 404),
        ).resolveLiveVideoId(const YouTubeChannelTarget('@nope')),
        throwsA(
          isA<YouTubeLiveResolveException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('a page without a canonical tag throws', () async {
      await expectLater(
        YouTubeLiveResolver(
          client: _ChunkedClient('<html>${'y' * 2000}</html>'),
        ).resolveLiveVideoId(const YouTubeChannelTarget('@NASA')),
        throwsA(isA<YouTubeLiveResolveException>()),
      );
    });
  });
}
