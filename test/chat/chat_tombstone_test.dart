import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_tombstone.dart';

void main() {
  group('formatChatTimeoutDuration', () {
    test('compacts common Twitch timeout lengths', () {
      expect(formatChatTimeoutDuration(const Duration(seconds: 1)), '1s');
      expect(formatChatTimeoutDuration(const Duration(seconds: 30)), '30s');
      expect(formatChatTimeoutDuration(const Duration(seconds: 60)), '1m');
      expect(formatChatTimeoutDuration(const Duration(seconds: 600)), '10m');
      expect(formatChatTimeoutDuration(const Duration(hours: 1)), '1h');
      expect(formatChatTimeoutDuration(const Duration(days: 1)), '1d');
    });
  });

  group('chatTombstoneMarker', () {
    test('labels each kind', () {
      expect(
        chatTombstoneMarker(const ChatTombstoneInfo.deleted()),
        ' —Deleted',
      );
      expect(
        chatTombstoneMarker(const ChatTombstoneInfo.banned()),
        ' —Banned',
      );
      expect(
        chatTombstoneMarker(
          const ChatTombstoneInfo.timedOut(Duration(seconds: 600)),
        ),
        ' —Timed out (10m)',
      );
    });
  });

  group('timeoutDurationFromExpiresAt', () {
    test('rounds remaining time from expires_at', () {
      final now = DateTime.utc(2024, 11, 27, 18, 2, 43);
      final expires = DateTime.utc(2024, 11, 27, 18, 12, 43);
      expect(
        timeoutDurationFromExpiresAt(expires, now: now),
        const Duration(minutes: 10),
      );
    });
  });
}
