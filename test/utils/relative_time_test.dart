import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/relative_time.dart';

void main() {
  final DateTime now = DateTime(2026, 9, 20, 14, 30);

  group('relativeTimeAgo', () {
    test('future and sub-minute deltas render as just now', () {
      expect(
        relativeTimeAgo(now.add(const Duration(seconds: 5)), now: now),
        'just now',
      );
      expect(
        relativeTimeAgo(now.subtract(const Duration(seconds: 42)), now: now),
        'just now',
      );
    });

    test('minutes and hours', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(minutes: 3)), now: now),
        '3m ago',
      );
      expect(
        relativeTimeAgo(
          now.subtract(const Duration(hours: 2, minutes: 10)),
          now: now,
        ),
        '2h ago',
      );
    });

    test('days switch to a date after a week', () {
      expect(
        relativeTimeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3d ago',
      );
      expect(
        relativeTimeAgo(now.subtract(const Duration(days: 8)), now: now),
        '12.09.2026',
      );
    });
  });
}
