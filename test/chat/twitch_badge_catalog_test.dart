import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

void main() {
  group('TwitchBadgeSet', () {
    test('parses a badge set with versions (helix shape)', () {
      final set = TwitchBadgeSet.fromJson(
        json.decode('''
        {
          "set_id": "moderator",
          "versions": [
            {
              "id": "1",
              "image_url_1x": "https://static-cdn.jtvnw.net/badges/v1/mod/1",
              "image_url_2x": "https://static-cdn.jtvnw.net/badges/v1/mod/2",
              "image_url_4x": "https://static-cdn.jtvnw.net/badges/v1/mod/3",
              "title": "Moderator",
              "description": "Moderator"
            }
          ]
        }
        ''') as Map<String, Object?>,
      );

      expect(set.setId, 'moderator');
      expect(set.versions, hasLength(1));
      expect(set.versions.single.id, '1');
      expect(set.versions.single.imageUrl2x,
          'https://static-cdn.jtvnw.net/badges/v1/mod/2');
      expect(set.versions.single.title, 'Moderator');
    });

    test('missing versions key parses as empty', () {
      final set = TwitchBadgeSet.fromJson(const {'set_id': 'vip'});
      expect(set.versions, isEmpty);
    });
  });

  group('settingsKeyForBadgeSetId', () {
    test('maps the dedicated categories', () {
      expect(settingsKeyForBadgeSetId('broadcaster'),
          SettingsKeys.TwitchChatBadgeBroadcaster);
      expect(settingsKeyForBadgeSetId('moderator'),
          SettingsKeys.TwitchChatBadgeModerator);
      expect(
          settingsKeyForBadgeSetId('vip'), SettingsKeys.TwitchChatBadgeVip);
      expect(settingsKeyForBadgeSetId('subscriber'),
          SettingsKeys.TwitchChatBadgeSubscriber);
      expect(settingsKeyForBadgeSetId('founder'),
          SettingsKeys.TwitchChatBadgeFounder);
      expect(settingsKeyForBadgeSetId('bits'),
          SettingsKeys.TwitchChatBadgeBits);
    });

    test('unknown set ids fall under Other', () {
      for (final setId
          in ['sub-gifter', 'staff', 'partner', 'premium', 'moments']) {
        expect(settingsKeyForBadgeSetId(setId),
            SettingsKeys.TwitchChatBadgeOther);
      }
    });

    test('badge toggle keys have kebab-case names', () {
      expect(SettingsKeys.TwitchChatBadgeBroadcaster.name,
          'twitch-chat-badge-broadcaster');
      expect(SettingsKeys.TwitchChatBadgeModerator.name,
          'twitch-chat-badge-moderator');
      expect(SettingsKeys.TwitchChatBadgeVip.name, 'twitch-chat-badge-vip');
      expect(SettingsKeys.TwitchChatBadgeSubscriber.name,
          'twitch-chat-badge-subscriber');
      expect(SettingsKeys.TwitchChatBadgeFounder.name,
          'twitch-chat-badge-founder');
      expect(
          SettingsKeys.TwitchChatBadgeBits.name, 'twitch-chat-badge-bits');
      expect(SettingsKeys.TwitchChatBadgeOther.name,
          'twitch-chat-badge-other');
    });
  });
}
