import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/eventsub_envelope.dart';

ChatMessageEvent eventFromFixture(String name) {
  final file = File('test/chat/fixtures/twitch/$name');
  return ChatMessageEvent.fromJson(
    json.decode(file.readAsStringSync()) as Map<String, Object?>,
  );
}

void main() {
  group('EventSubEnvelope', () {
    test('parses session_welcome metadata', () {
      final envelope = EventSubEnvelope.fromJson(
        json.decode('''
        {
          "metadata": {
            "message_id": "96a3f3b5-5e2d-4e6f-9a1b-2c3d4e5f6a7b",
            "message_type": "session_welcome",
            "message_timestamp": "2026-08-04T10:00:00.000Z"
          },
          "payload": {
            "session": {
              "id": "session-1",
              "status": "connected",
              "keepalive_timeout_seconds": 30,
              "reconnect_url": null
            }
          }
        }
        ''') as Map<String, Object?>,
      );

      expect(envelope.metadata.messageType, 'session_welcome');
      expect(envelope.metadata.subscriptionType, isNull);
      expect((envelope.payload['session'] as Map)['id'], 'session-1');
    });

    test('parses notification metadata with subscription type', () {
      final envelope = EventSubEnvelope.fromJson(
        json.decode('''
        {
          "metadata": {
            "message_id": "1111",
            "message_type": "notification",
            "message_timestamp": "2026-08-04T10:00:00.000Z",
            "subscription_type": "channel.chat.message",
            "subscription_version": "1"
          },
          "payload": { "subscription": {}, "event": {} }
        }
        ''') as Map<String, Object?>,
      );

      expect(envelope.metadata.messageType, 'notification');
      expect(envelope.metadata.subscriptionType, 'channel.chat.message');
    });
  });

  group('ChatMessageEvent', () {
    test('parses a plain text message (real docs payload)', () {
      final event = eventFromFixture('channel_chat_message_text.json');

      expect(event.chatterUserName, 'viewer32');
      expect(event.messageId, 'cc106a89-1814-919d-454c-f4f2f970aae7');
      expect(event.color, '#00FF7F');
      expect(event.message.text, 'Hi chat');
      expect(event.message.fragments, hasLength(1));
      expect(event.message.fragments.first.type, 'text');
      expect(event.message.fragments.first.emote, isNull);
    });

    test('parses emote fragments', () {
      final event = eventFromFixture('channel_chat_message_emote.json');

      expect(event.color, isNull);
      expect(event.message.fragments, hasLength(3));
      final emoteFragment = event.message.fragments[1];
      expect(emoteFragment.type, 'emote');
      expect(emoteFragment.text, 'Kappa');
      expect(emoteFragment.emote?.id, '25');
      expect(twitchEmoteUrl(emoteFragment.emote!.id),
          'https://static-cdn.jtvnw.net/emoticons/v2/25/default/dark/2.0');
    });

    test('keeps cheermote fragments as plain text', () {
      final event = eventFromFixture('channel_chat_message_cheermote.json');

      expect(event.message.fragments, hasLength(2));
      expect(event.message.fragments[1].type, 'cheermote');
      expect(event.message.fragments[1].text, 'pogchamp');
      expect(event.message.fragments[1].emote, isNull);
    });
  });
}
