import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_notification.dart';

void main() {
  test('ChatMessageEvent parses reply, message_type, and mention fragments',
      () {
    final event = ChatMessageEvent.fromJson({
      'broadcaster_user_id': 'b1',
      'chatter_user_id': 'c1',
      'chatter_user_login': 'alice',
      'chatter_user_name': 'Alice',
      'message_id': 'm1',
      'message_type': 'user_intro',
      'color': '#FF0000',
      'badges': <Object>[],
      'message': {
        'text': '@Bob hi',
        'fragments': [
          {
            'type': 'mention',
            'text': '@Bob',
            'mention': {
              'user_id': 'u2',
              'user_login': 'bob',
              'user_name': 'Bob',
            },
          },
          {'type': 'text', 'text': ' hi'},
        ],
      },
      'reply': {
        'parent_message_id': 'p1',
        'parent_message_body': 'hello there',
        'parent_user_id': 'u2',
        'parent_user_name': 'Bob',
        'parent_user_login': 'bob',
        'thread_message_id': 'p1',
        'thread_user_id': 'u2',
        'thread_user_name': 'Bob',
        'thread_user_login': 'bob',
      },
    });

    expect(event.messageType, 'user_intro');
    expect(event.reply?.parentUserName, 'Bob');
    expect(event.message.fragments.first.type, 'mention');
    expect(event.message.fragments.first.mention?.userName, 'Bob');
  });

  test('ChatNotificationEvent parses system_message and watch_streak', () {
    final event = ChatNotificationEvent.fromJson({
      'broadcaster_user_id': 'b1',
      'chatter_user_id': 'c1',
      'chatter_user_login': 'alice',
      'chatter_user_name': 'Alice',
      'message_id': 'n1',
      'system_message': 'Alice is currently on a 5-stream streak!',
      'notice_type': 'watch_streak',
      'color': '#BF94FF',
      'badges': <Object>[],
      'message': {'text': '', 'fragments': <Object>[]},
      'watch_streak': {
        'streak_count': 5,
        'channel_points_awarded': 450,
      },
    });

    expect(event.noticeType, 'watch_streak');
    expect(event.watchStreak?.streakCount, 5);
    expect(chatNoticeChrome(event.noticeType).icon, ChatNoticeIconSeed.flame);
  });

  test('shared_chat_ notice types normalize for chrome', () {
    expect(
      chatNoticeChrome('shared_chat_sub_gift').color,
      ChatNoticeColorSeed.sub,
    );
  });

  test('official message fixture still parses', () async {
    final raw = await File(
      'test/chat/fixtures/twitch/channel_chat_message_text.json',
    ).readAsString();
    final event = ChatMessageEvent.fromJson(
      json.decode(raw) as Map<String, Object?>,
    );
    expect(event.messageType, 'text');
    expect(event.reply, isNull);
  });
}
