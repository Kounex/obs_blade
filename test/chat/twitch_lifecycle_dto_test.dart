import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';

Map<String, Object?> fixture(String name) =>
    json.decode(File('test/chat/fixtures/twitch/$name.json').readAsStringSync())
        as Map<String, Object?>;

void main() {
  group('lifecycle event DTOs', () {
    test('message_delete parses the documented example payload', () {
      final event = ChatMessageDeleteEvent.fromJson(
          fixture('channel_chat_message_delete'));
      expect(event.messageId, 'e860a7a5-58d3-4959-9c5f-0f4dc9b5b0a2');
      expect(event.targetUserId, '7734');
      expect(event.userName, 'Cool_Mod');
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
}
