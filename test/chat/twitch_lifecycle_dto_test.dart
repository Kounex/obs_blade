import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_moderate_event.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';

Map<String, Object?> fixture(String name) =>
    json.decode(File('test/chat/fixtures/twitch/$name.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  group('lifecycle event DTOs', () {
    test('message_delete parses the documented example payload', () {
      final event = ChatMessageDeleteEvent.fromJson(
          fixture('channel_chat_message_delete'));
      expect(event.messageId, 'ab24e0b0-2260-4bac-94e4-05eedd4ecd0e');
      expect(event.targetUserId, '7734');

      /// Twitch's real payload carries no deleting-moderator field — the
      /// actor stays unknown and the row's reveal line stays hidden.
      expect(event.userName, isNull);
    });

    test('clear_user_messages parses the documented example payload', () {
      final event = ChatClearUserMessagesEvent.fromJson(
          fixture('channel_chat_clear_user_messages'));
      expect(event.targetUserId, '7734');
    });

    test('clear parses the documented example payload', () {
      final event = ChatClearEvent.fromJson(fixture('channel_chat_clear'));
      expect(event.broadcasterUserId, '1337');
    });

    test('message_delete without message_id throws', () {
      expect(
        () => ChatMessageDeleteEvent.fromJson(const {'target_user_id': '1'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('clear_user_messages without target_user_id throws', () {
      expect(
        () => ChatClearUserMessagesEvent.fromJson(const {}),
        throwsA(isA<TypeError>()),
      );
    });

    test('clear without broadcaster_user_id throws', () {
      expect(
        () => ChatClearEvent.fromJson(const {}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('channel.moderate v2 DTO', () {
    test('delete action parses the real payload shape', () {
      final event =
          ChannelModerateEvent.fromJson(fixture('channel_moderate_delete'));
      expect(event.action, 'delete');
      expect(event.moderatorUserName, 'quotrok');
      expect(event.delete?.messageId, 'ab24e0b0-2260-4bac-94e4-05eedd4ecd0e');
      expect(event.delete?.userName, 'TwitchDev');
    });

    test('a non-delete action yields no delete payload', () {
      final event =
          ChannelModerateEvent.fromJson(fixture('channel_moderate_timeout'));
      expect(event.action, 'timeout');
      expect(event.moderatorUserName, 'quotrok');
      expect(event.delete, isNull);
      expect(event.timeout?.userId, '141981764');
      expect(event.timeout?.expiresAt, isNotNull);
    });

    test('delete without message_id throws', () {
      expect(
        () => ChannelModerateEvent.fromJson(const {
          'action': 'delete',
          'moderator_user_name': 'quotrok',
          'delete': <String, Object?>{},
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
