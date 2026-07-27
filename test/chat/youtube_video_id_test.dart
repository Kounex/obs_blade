import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/youtube_video_id.dart';

void main() {
  group('extractYouTubeVideoId', () {
    test('bare id', () {
      expect(extractYouTubeVideoId('m-i_0DcfF1s'), 'm-i_0DcfF1s');
    });

    test('watch URL', () {
      expect(
        extractYouTubeVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('live_chat URL (previous Hive fixture style)', () {
      expect(
        extractYouTubeVideoId(
          'https://www.youtube.com/live_chat?v=dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('legacy brittle split would return https: for full URLs', () {
      final stored = 'https://www.youtube.com/live_chat?v=dQw4w9WgXcQ';
      final legacy = stored.split(RegExp(r'[/?&]'))[0];
      expect(legacy, 'https:');
      expect(extractYouTubeVideoId(stored), 'dQw4w9WgXcQ');
    });

    test('youtu.be short link', () {
      expect(
        extractYouTubeVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('live path', () {
      expect(
        extractYouTubeVideoId('https://www.youtube.com/live/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('embed path', () {
      expect(
        extractYouTubeVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('scheme-less URL', () {
      expect(
        extractYouTubeVideoId('www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('null / empty', () {
      expect(extractYouTubeVideoId(null), isNull);
      expect(extractYouTubeVideoId(''), isNull);
      expect(extractYouTubeVideoId('   '), isNull);
    });

    test('garbage', () {
      expect(extractYouTubeVideoId('not-a-youtube-link'), isNull);
    });
  });
}
