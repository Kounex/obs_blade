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
    expect(event.watchStreak?.channelPointsAwarded, 450);
    expect(chatNoticeChrome(event.noticeType).icon, ChatNoticeIconSeed.flame);
    expect(chatNoticeMetaText(event), '450');
  });

  test('shared_chat_ notice types normalize for chrome', () {
    expect(
      chatNoticeChrome('shared_chat_sub_gift').color,
      ChatNoticeColorSeed.sub,
    );
  });

  test('ChatNotificationEvent parses announcement.color', () {
    final event = ChatNotificationEvent.fromJson({
      'broadcaster_user_id': 'b1',
      'chatter_user_id': 'c1',
      'chatter_user_login': 'alice',
      'chatter_user_name': 'Alice',
      'message_id': 'a1',
      'system_message': '',
      'notice_type': 'announcement',
      'color': '#00FF00',
      'badges': <Object>[],
      'message': {
        'text': 'Hello chat',
        'fragments': [
          {'type': 'text', 'text': 'Hello chat'},
        ],
      },
      'announcement': {'color': 'ORANGE'},
    });

    expect(event.announcement?.color, 'orange');
    // Top-level color is the chatter name hex — not the highlight.
    expect(event.color, '#00FF00');
  });

  test('shared_chat_announcement promotes announcement block', () {
    final event = ChatNotificationEvent.fromJson({
      'broadcaster_user_id': 'b1',
      'chatter_user_id': 'c1',
      'chatter_user_login': 'alice',
      'chatter_user_name': 'Alice',
      'message_id': 'a2',
      'system_message': '',
      'notice_type': 'shared_chat_announcement',
      'shared_chat_announcement': {'color': 'blue'},
    });
    expect(event.announcement?.color, 'blue');
  });

  test('shared_chat_watch_streak promotes typed block for meta', () {
    final event = ChatNotificationEvent.fromJson({
      'broadcaster_user_id': 'b1',
      'chatter_user_id': 'c1',
      'chatter_user_login': 'alice',
      'chatter_user_name': 'Alice',
      'message_id': 'n2',
      'system_message': 'Alice is currently on a 5-stream streak!',
      'notice_type': 'shared_chat_watch_streak',
      'shared_chat_watch_streak': {
        'streak_count': 5,
        'channel_points_awarded': 450,
      },
    });
    expect(event.watchStreak?.channelPointsAwarded, 450);
    expect(chatNoticeMetaText(event), '450');
  });

  test('chatNoticeMetaText covers raid / gifts / bits / charity', () {
    ChatNotificationEvent base({
      required String noticeType,
      Map<String, Object?>? extra,
    }) =>
        ChatNotificationEvent.fromJson({
          'broadcaster_user_id': 'b1',
          'chatter_user_id': 'c1',
          'chatter_user_login': 'alice',
          'chatter_user_name': 'Alice',
          'message_id': 'n3',
          'system_message': 'Alice did a thing',
          'notice_type': noticeType,
          ...?extra,
        });

    expect(
      chatNoticeMetaText(
        base(
          noticeType: 'raid',
          extra: {
            'raid': {'viewer_count': 1200, 'user_name': 'Other'},
          },
        ),
      ),
      '1.2k',
    );
    expect(
      chatNoticeMetaText(
        base(
          noticeType: 'community_sub_gift',
          extra: {
            'community_sub_gift': {'total': 5, 'sub_plan': '1000'},
          },
        ),
      ),
      '5 · Tier 1',
    );
    expect(
      chatNoticeMetaText(
        base(
          noticeType: 'sub_gift',
          extra: {
            'sub_gift': {'sub_plan': '2000', 'recipient_user_name': 'Bob'},
          },
        ),
      ),
      'Tier 2',
    );
    expect(
      chatNoticeMetaText(
        base(
          noticeType: 'bits_badge_tier',
          extra: {
            'bits_badge_tier': {'tier': 1000},
          },
        ),
      ),
      '1k',
    );
    expect(
      chatNoticeMetaText(
        base(
          noticeType: 'charity_donation',
          extra: {
            'charity_donation': {
              'charity_name': 'Example',
              'amount': {
                'value': 500,
                'decimal_places': 2,
                'currency': 'USD',
              },
            },
          },
        ),
      ),
      '5.00 USD',
    );
    expect(
      chatNoticeMetaText(
        base(noticeType: 'sub'),
      ),
      isNull,
    );
    expect(
      chatNoticeMetaText(
        base(
          noticeType: 'watch_streak',
          extra: {
            'watch_streak': {
              'streak_count': 3,
              'channel_points_awarded': 0,
            },
          },
        ),
      ),
      isNull,
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
