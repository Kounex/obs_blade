import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';

void main() {
  group('TwitchUser', () {
    test('parses created_at from Helix users payload', () {
      final user = TwitchUser.fromJson({
        'id': '141981764',
        'login': 'twitch',
        'display_name': 'Twitch',
        'profile_image_url': 'https://example/avatar.png',
        'created_at': '2007-05-22T13:37:00Z',
      });

      expect(user.id, '141981764');
      expect(user.login, 'twitch');
      expect(user.displayName, 'Twitch');
      expect(user.profileImageUrl, 'https://example/avatar.png');
      expect(user.createdAt, DateTime.utc(2007, 5, 22, 13, 37));
    });

    test('created_at is null when absent or invalid', () {
      final without = TwitchUser.fromJson({
        'id': '1',
        'login': 'someone',
      });
      final invalid = TwitchUser.fromJson({
        'id': '1',
        'login': 'someone',
        'created_at': 'not-a-date',
      });

      expect(without.createdAt, isNull);
      expect(invalid.createdAt, isNull);
    });
  });
}
