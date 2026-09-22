import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/kick_channel_slug.dart';

void main() {
  group('extractKickChannelSlug', () {
    test('bare slugs pass through, lowercased', () {
      expect(extractKickChannelSlug('SomeChannel'), 'somechannel');
      expect(extractKickChannelSlug('with_underscore-9'), 'with_underscore-9');
    });

    test('channel page URLs', () {
      expect(
        extractKickChannelSlug('https://kick.com/SomeChannel'),
        'somechannel',
      );
      expect(extractKickChannelSlug('kick.com/somechannel'), 'somechannel');
      expect(
        extractKickChannelSlug('https://www.kick.com/somechannel?x=1'),
        'somechannel',
      );
    });

    test('popout chat URLs (the OBS-dock form)', () {
      expect(
        extractKickChannelSlug('https://kick.com/popout/SomeChannel/chat'),
        'somechannel',
      );
    });

    test('junk returns null', () {
      expect(extractKickChannelSlug(null), isNull);
      expect(extractKickChannelSlug(''), isNull);
      expect(extractKickChannelSlug('   '), isNull);
      expect(extractKickChannelSlug('not a slug!!'), isNull);
      expect(extractKickChannelSlug('https://twitch.tv/somechannel'), isNull);
      expect(extractKickChannelSlug('https://kick.com'), isNull);
      expect(extractKickChannelSlug('https://kick.com/'), isNull);
    });
  });
}
