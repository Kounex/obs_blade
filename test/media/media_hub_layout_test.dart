import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/media/media_hub_layout.dart';
import 'package:obs_blade/types/classes/media/media_status.dart';

void main() {
  group('MediaHubLayout', () {
    test('arrange: manual order first, unknown names keep OBS order', () {
      const layout = MediaHubLayout(order: ['Horn', 'Gone', 'Applause']);
      expect(layout.arrange(['Applause', 'Intro', 'Horn', 'Outro']), [
        'Horn',
        'Applause',
        'Intro',
        'Outro',
      ]);
    });

    test('withHidden toggles, withOrder keeps hidden', () {
      final layout = MediaHubLayout.empty.withHidden('Horn', true).withOrder([
        'Horn',
        'Intro',
      ]);
      expect(layout.isHidden('Horn'), isTrue);
      expect(layout.order, ['Horn', 'Intro']);
      expect(layout.withHidden('Horn', false).isHidden('Horn'), isFalse);
    });

    test('malformed settings read as the default layout', () {
      for (final raw in [
        null,
        'garbage',
        42,
        {'name:Home': 'not a map'},
        {
          'name:Home': {'hidden': 'x', 'order': 3},
        },
      ]) {
        final layout = readMediaHubLayout(raw, 'name:Home');
        expect(layout.hidden, isEmpty, reason: '$raw');
        expect(layout.order, isEmpty, reason: '$raw');
      }
    });

    test('write keeps other connections, round-trips through JSON', () {
      final raw = {
        'host:10.0.0.2': {
          'hidden': ['A'],
          'order': <String>[],
        },
      };
      final written = writeMediaHubLayout(
        raw,
        'name:Home',
        const MediaHubLayout(hidden: {'Horn'}, order: ['Horn', 'Intro']),
      );
      expect(written['host:10.0.0.2'], raw['host:10.0.0.2']);
      final back = readMediaHubLayout(written, 'name:Home');
      expect(back.hidden, {'Horn'});
      expect(back.order, ['Horn', 'Intro']);
    });

    test('connection key prefers the saved name', () {
      expect(
        mediaHubConnectionKey(connectionName: 'Home', host: '10.0.0.2'),
        'name:Home',
      );
      expect(mediaHubConnectionKey(host: '10.0.0.2'), 'host:10.0.0.2');
    });
  });

  group('MediaStatus', () {
    final t0 = DateTime(2026, 9, 27, 12);

    test('playing extrapolates the cursor and wraps by duration', () {
      final status = MediaStatus(
        state: kMediaStatePlaying,
        duration: 10000,
        cursor: 9000,
        receivedAt: t0,
      );
      expect(status.cursorAt(t0.add(const Duration(milliseconds: 500))), 9500);
      expect(status.cursorAt(t0.add(const Duration(seconds: 2))), 1000);
      expect(
        status.progressAt(t0.add(const Duration(milliseconds: 500))),
        0.95,
      );
    });

    test('paused holds the cursor; no duration → no progress', () {
      final paused = MediaStatus(
        state: kMediaStatePaused,
        duration: 10000,
        cursor: 4000,
        receivedAt: t0,
      );
      expect(paused.cursorAt(t0.add(const Duration(seconds: 5))), 4000);
      expect(paused.active, isTrue);
      final ended = MediaStatus(state: 'OBS_MEDIA_STATE_ENDED', receivedAt: t0);
      expect(ended.progressAt(t0), isNull);
      expect(ended.active, isFalse);
    });

    test('formatMediaTime', () {
      expect(formatMediaTime(0), '0:00');
      expect(formatMediaTime(65000), '1:05');
      expect(formatMediaTime(3725000), '1:02:05');
    });
  });
}
