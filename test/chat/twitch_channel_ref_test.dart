import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';

void main() {
  group('kTwitchChatScopes', () {
    test('contains the multi-chat discovery + mod action scopes', () {
      expect(kTwitchChatScopes, containsAll(<String>[
        'user:read:follows',
        'user:read:subscriptions',
        'user:read:moderated_channels',
        'moderator:read:followers',
        'moderator:manage:chat_messages',
        'moderator:manage:banned_users',
      ]));
    });
  });

  group('SettingsKeys multi-chat', () {
    test('name map entries are kebab-case', () {
      expect(SettingsKeys.NativeChatChannels.name, 'native-chat-channels');
      expect(SettingsKeys.SelectedNativeChatChannelId.name,
          'selected-native-chat-channel-id');
    });
  });

  group('TwitchChannelRef', () {
    final addedAt = DateTime.utc(2026, 8, 9, 12, 0, 0);
    final ref = TwitchChannelRef(
      id: 'chan-1',
      login: 'someone',
      displayName: 'SomeOne',
      addedAt: addedAt,
    );

    test('json round-trip', () {
      final decoded = TwitchChannelRef.fromJson(ref.toJson());

      expect(decoded.id, 'chan-1');
      expect(decoded.login, 'someone');
      expect(decoded.displayName, 'SomeOne');
      expect(decoded.addedAt, addedAt);
    });

    test('equality and hashCode ride the channel id', () {
      final sameId = TwitchChannelRef(
        id: 'chan-1',
        login: 'renamed',
        displayName: 'Renamed',
        addedAt: DateTime.utc(2026, 8, 10),
      );
      final otherId = TwitchChannelRef(
        id: 'chan-2',
        login: 'someone',
        displayName: 'SomeOne',
        addedAt: addedAt,
      );

      expect(ref, sameId);
      expect(ref.hashCode, sameId.hashCode);
      expect(ref, isNot(otherId));
    });
  });
}
