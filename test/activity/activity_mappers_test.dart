import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/activity/activity_event.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/utils/activity/activity_mappers.dart';

final DateTime _sent = DateTime.utc(2026, 10, 2, 20);

ActivityEvent? _twitch(String type, Map<String, Object?> event) =>
    twitchActivityFromEventSub(
      type: type,
      event: event,
      channelId: '1337',
      messageId: 'envelope-1',
      sentAt: _sent,
    );

Map<String, Object?> _notice(String type, Map<String, Object?> extra) => {
  'broadcaster_user_id': '1337',
  'chatter_user_id': '99',
  'chatter_user_login': 'fan',
  'chatter_user_name': 'Fan',
  'chatter_is_anonymous': false,
  'message_id': 'chat-msg-1',
  'notice_type': type,
  'message': {'text': 'hi'},
  ...extra,
};

/// Relay frame as the relay sends it (payloads from KickDevDocs
/// events/event-types.md).
Map<String, Object?> _kick(String type, Map<String, Object?> payload) => {
  'type': 'event',
  'seq': 3,
  'message_id': '01KICKMSG',
  'event_type': type,
  'event_version': '1',
  'timestamp': '2026-10-02T20:00:05Z',
  'payload': {
    'broadcaster': {
      'user_id': 123456789,
      'username': 'broadcaster_name',
      'channel_slug': 'broadcaster_channel',
    },
    ...payload,
  },
};

const Map<String, Object?> _kickFan = {
  'is_anonymous': false,
  'user_id': 987654321,
  'username': 'follower_name',
  'channel_slug': 'follower_channel',
};

void main() {
  group('Twitch EventSub', () {
    test('follow keys on the follower so live + backfill match', () {
      final live = _twitch('channel.follow', {
        'user_id': '99',
        'user_login': 'fan',
        'user_name': 'Fan',
        'followed_at': '2026-10-02T19:59:58Z',
      })!;
      final backfill = twitchActivityFromFollower({
        'user_id': '99',
        'user_login': 'fan',
        'user_name': 'Fan',
        'followed_at': '2026-10-02T19:59:58Z',
      }, '1337')!;
      expect(live.kind, ActivityKind.follow);
      expect(live.id, backfill.id);
      expect(live.timestamp, DateTime.utc(2026, 10, 2, 19, 59, 58));
    });

    test('bits use: a cheer', () {
      final event = _twitch('channel.bits.use', {
        'user_id': '99',
        'user_login': 'fan',
        'user_name': 'Fan',
        'bits': 100,
        'type': 'cheer',
        'message': {'text': 'Cheer100 gg', 'fragments': []},
      })!;
      expect(event.kind, ActivityKind.cheer);
      expect(event.actor.name, 'Fan');
      expect(event.amount!.value, 100);
      expect(event.amount!.unit, ActivityUnit.bits);
      expect(event.title, isNull);
      expect(event.message, 'Cheer100 gg');
      expect(event.isBig, isTrue);
    });

    test('bits use: Power-ups carry their name, no message', () {
      final gigantify = _twitch('channel.bits.use', {
        'user_id': '99',
        'user_login': 'fan',
        'user_name': 'Fan',
        'bits': 50,
        'type': 'power_up',
        'power_up': {'type': 'gigantify_an_emote', 'emote': null},
      })!;
      expect(gigantify.kind, ActivityKind.cheer);
      expect(gigantify.title, 'Gigantify an Emote');
      expect(gigantify.message, isNull);
      final custom = _twitch('channel.bits.use', {
        'user_id': '99',
        'user_login': 'fan',
        'user_name': 'Fan',
        'bits': 300,
        'type': 'custom_power_up',
        'custom_power_up': {'title': 'Hydrate', 'reward_id': 'r'},
      })!;
      expect(custom.title, 'Hydrate');
      final unknown = _twitch('channel.bits.use', {
        'user_id': '99',
        'user_name': 'Fan',
        'bits': 10,
        'type': 'power_up',
        'power_up': {'type': 'something_new'},
      })!;
      expect(unknown.title, 'a Power-up');
    });

    test('channel points redemption', () {
      final event = _twitch(
        'channel.channel_points_custom_reward_redemption.add',
        {
          'id': 'red-1',
          'user_id': '99',
          'user_login': 'fan',
          'user_name': 'Fan',
          'user_input': 'play song',
          'status': 'unfulfilled',
          'redeemed_at': '2026-10-02T19:58:00Z',
          'reward': {'id': 'r', 'title': 'Song request', 'cost': 500},
        },
      )!;
      expect(event.kind, ActivityKind.redemption);
      expect(event.title, 'Song request');
      expect(event.amount!.unit, ActivityUnit.points);
      expect(event.message, 'play song');
      expect(event.isBig, isFalse);
    });

    test('hype train begin and end share one row id', () {
      final begin = _twitch('channel.hype_train.begin', {
        'id': 'train-1',
        'level': 1,
        'total': 100,
        'type': 'regular',
        'started_at': '2026-10-02T19:50:00Z',
        'top_contributions': [
          {'user_name': 'Fan', 'type': 'bits', 'total': 100},
        ],
      })!;
      final end = _twitch('channel.hype_train.end', {
        'id': 'train-1',
        'level': 4,
        'total': 9000,
        'type': 'regular',
        'started_at': '2026-10-02T19:50:00Z',
        'ended_at': '2026-10-02T20:00:00Z',
      })!;
      expect(begin.id, end.id);
      expect(end.amount!.value, 4);
      expect(end.title, 'ended');
      expect(begin.recipients, ['Fan']);
    });

    test('sub / resub / raid / charity notices', () {
      final sub = _twitch(
        'channel.chat.notification',
        _notice('sub', {
          'sub': {'sub_tier': '2000', 'is_prime': false, 'duration_months': 1},
        }),
      )!;
      expect(sub.kind, ActivityKind.sub);
      expect(sub.tier, '2000');

      final resub = _twitch(
        'channel.chat.notification',
        _notice('resub', {
          'resub': {
            'cumulative_months': 14,
            'sub_tier': '1000',
            'is_prime': true,
          },
        }),
      )!;
      expect(resub.kind, ActivityKind.resub);
      expect(resub.tier, 'prime');
      expect(resub.amount!.value, 14);

      final continued = _twitch(
        'channel.chat.notification',
        _notice('gift_paid_upgrade', {
          'gift_paid_upgrade': {
            'gifter_is_anonymous': false,
            'gifter_user_id': '7',
            'gifter_user_name': 'Santa',
            'gifter_user_login': 'santa',
          },
        }),
      )!;
      expect(continued.kind, ActivityKind.sub);
      expect(continued.title, 'Continued the sub from Santa');
      final continuedAnon = _twitch(
        'channel.chat.notification',
        _notice('gift_paid_upgrade', {
          'gift_paid_upgrade': {'gifter_is_anonymous': true},
        }),
      )!;
      expect(continuedAnon.title, 'Continued a gifted sub');
      final prime = _twitch(
        'channel.chat.notification',
        _notice('prime_paid_upgrade', {
          'prime_paid_upgrade': {'sub_tier': '1000'},
        }),
      )!;
      expect(prime.tier, '1000');
      expect(prime.title, 'Upgraded from Prime');

      final raid = _twitch(
        'channel.chat.notification',
        _notice('raid', {
          'raid': {
            'user_id': '55',
            'user_name': 'Raider',
            'user_login': 'raider',
            'viewer_count': 321,
          },
        }),
      )!;
      expect(raid.kind, ActivityKind.raid);
      expect(raid.actor.name, 'Raider');
      expect(raid.amount!.value, 321);

      final charity = _twitch(
        'channel.chat.notification',
        _notice('charity_donation', {
          'charity_donation': {
            'charity_name': 'Good Cause',
            'amount': {'value': 2550, 'decimal_places': 2, 'currency': 'USD'},
          },
        }),
      )!;
      expect(charity.kind, ActivityKind.charity);
      expect(charity.amount!.value, 25.5);
      expect(charity.amount!.unit, 'USD');
      expect(charity.title, 'Good Cause');
    });

    test('gift bomb pieces share the community gift id', () {
      final bomb = _twitch(
        'channel.chat.notification',
        _notice('community_sub_gift', {
          'community_sub_gift': {'id': 'cg-9', 'total': 5, 'sub_tier': '1000'},
        }),
      )!;
      final piece = _twitch(
        'channel.chat.notification',
        _notice('sub_gift', {
          'message_id': 'chat-msg-2',
          'sub_gift': {
            'recipient_user_name': 'Lucky',
            'community_gift_id': 'cg-9',
            'sub_tier': '1000',
          },
        }),
      )!;
      expect(bomb.id, piece.id);
      expect(bomb.amount!.value, 5);
      expect(piece.recipients, ['Lucky']);
      expect(piece.amount, isNull);
    });

    test('single gift without a bomb is its own row with 1 sub', () {
      final gift = _twitch(
        'channel.chat.notification',
        _notice('sub_gift', {
          'sub_gift': {'recipient_user_name': 'Lucky', 'sub_tier': '1000'},
        }),
      )!;
      expect(gift.amount!.value, 1);
      expect(gift.id, contains('chat-msg-1'));
    });

    test('shared chat notices from other channels are not own activity', () {
      expect(
        _twitch(
          'channel.chat.notification',
          _notice('shared_chat_sub', {
            'shared_chat_sub': {'sub_tier': '1000'},
          }),
        ),
        isNull,
      );
    });

    test('announcements, streaks and unknown types are skipped', () {
      for (final type in ['announcement', 'watch_streak', 'bits_badge_tier']) {
        expect(_twitch('channel.chat.notification', _notice(type, {})), isNull);
      }
      expect(_twitch('channel.unknown', {}), isNull);
    });
  });

  group('YouTube', () {
    YouTubeChatMessage message(String type, Map<String, Object?> details) =>
        YouTubeChatMessage.fromJson({
          'id': 'yt-1',
          'snippet': {
            'type': type,
            'publishedAt': '2026-10-02T20:00:00Z',
            'authorChannelId': 'UCfan',
            ...details,
          },
          'authorDetails': {'channelId': 'UCfan', 'displayName': 'Fan'},
        });

    test('super chat keeps currency and display string', () {
      final event = youTubeActivityFromMessage(
        message('superChatEvent', {
          'superChatDetails': {
            'amountMicros': '5000000',
            'currency': 'USD',
            'amountDisplayString': r'$5.00',
            'userComment': 'love it',
          },
        }),
        'UCme',
      )!;
      expect(event.kind, ActivityKind.superChat);
      expect(event.amount!.value, 5);
      expect(event.amount!.unit, 'USD');
      expect(event.amount!.display, r'$5.00');
      expect(event.message, 'love it');
      expect(event.id, 'youtube:UCme:yt-1');
    });

    test('memberships and gifting', () {
      expect(
        youTubeActivityFromMessage(
          message('newSponsorEvent', {
            'newSponsorDetails': {'memberLevelName': 'Gold'},
          }),
          'UCme',
        )!.kind,
        ActivityKind.member,
      );
      final gift = youTubeActivityFromMessage(
        message('membershipGiftingEvent', {
          'membershipGiftingDetails': {'giftMembershipsCount': 10},
        }),
        'UCme',
      )!;
      expect(gift.kind, ActivityKind.memberGift);
      expect(gift.amount!.value, 10);
    });

    test('plain text is not activity', () {
      expect(
        youTubeActivityFromMessage(
          message('textMessageEvent', {
            'textMessageDetails': {'messageText': 'hi'},
          }),
          'UCme',
        ),
        isNull,
      );
    });
  });

  group('Kick relay', () {
    test('follow', () {
      final event = kickActivityFromRelay(
        _kick('channel.followed', {'follower': _kickFan}),
      )!;
      expect(event.kind, ActivityKind.follow);
      expect(event.channelId, '123456789');
      expect(event.actor.id, '987654321');
      expect(event.actor.name, 'follower_name');
      expect(event.primarySource, ActivitySource.kickRelay);
      expect(event.id, 'kick:123456789:follow:987654321');
    });

    test('KICKs gift', () {
      final event = kickActivityFromRelay(
        _kick('kicks.gifted', {
          'sender': _kickFan,
          'gift': {
            'amount': 500,
            'name': 'Rage Quit',
            'type': 'LEVEL_UP',
            'tier': 'MID',
            'message': 'w',
            'pinned_time_seconds': 600,
          },
          'created_at': '2025-10-20T04:00:08.634Z',
        }),
      )!;
      expect(event.kind, ActivityKind.kicks);
      expect(event.amount!.value, 500);
      expect(event.amount!.unit, ActivityUnit.kicks);
      expect(event.title, 'Rage Quit');
      expect(event.message, 'w');
      expect(event.isBig, isTrue);
    });

    test('gifts: anonymous gifter, giftees counted', () {
      final event = kickActivityFromRelay(
        _kick('channel.subscription.gifts', {
          'gifter': {'is_anonymous': true, 'user_id': null, 'username': null},
          'giftees': [
            {'user_id': 1, 'username': 'a'},
            {'user_id': 2, 'username': 'b'},
          ],
          'created_at': '2025-01-14T16:08:06Z',
        }),
      )!;
      expect(event.kind, ActivityKind.giftSub);
      expect(event.actor.anonymous, isTrue);
      expect(event.amount!.value, 2);
      expect(event.recipients, ['a', 'b']);
    });

    test('renewal carries months; new sub does not', () {
      final renewal = kickActivityFromRelay(
        _kick('channel.subscription.renewal', {
          'subscriber': _kickFan,
          'duration': 3,
          'created_at': '2025-01-14T16:08:06Z',
        }),
      )!;
      expect(renewal.kind, ActivityKind.resub);
      expect(renewal.amount!.value, 3);
      final fresh = kickActivityFromRelay(
        _kick('channel.subscription.new', {
          'subscriber': _kickFan,
          'duration': 1,
          'created_at': '2025-01-14T16:08:06Z',
        }),
      )!;
      expect(fresh.kind, ActivityKind.sub);
      expect(fresh.amount, isNull);
    });

    test('redemption updates key on the redemption id', () {
      Map<String, Object?> redemption(String status) =>
          _kick('channel.reward.redemption.updated', {
            'id': '01KBHE78QE4HZY1617DK5FC7YD',
            'user_input': 'unban me',
            'status': status,
            'redeemed_at': '2025-12-02T22:54:19.323Z',
            'reward': {'id': 'r', 'title': 'Unban Request', 'cost': 1000},
            'redeemer': {'user_id': 123, 'username': 'naughty-user'},
          });
      final pending = kickActivityFromRelay(redemption('pending'))!;
      final accepted = kickActivityFromRelay(redemption('accepted'))!;
      expect(pending.id, accepted.id);
      expect(pending.title, 'Unban Request');
    });

    test('stream status is a session signal, not a row', () {
      final frame = _kick('livestream.status.updated', {
        'is_live': true,
        'title': 'Stream',
        'started_at': '2025-01-01T11:00:00+11:00',
        'ended_at': null,
      });
      expect(kickActivityFromRelay(frame), isNull);
      final (channel, live, at) = kickRelayLiveStatus(frame)!;
      expect(channel, '123456789');
      expect(live, isTrue);
      expect(at, DateTime.utc(2025, 1, 1));
    });
  });

  group('Kick Pusher', () {
    test('sub / gift / host', () {
      final sub = kickActivityFromPusher(
        kind: 'subscription',
        channelId: '42',
        eventId: 'p1',
        at: _sent,
        username: 'Fan',
        months: 6,
      )!;
      expect(sub.kind, ActivityKind.resub);
      expect(sub.actor.login, 'fan');
      final gift = kickActivityFromPusher(
        kind: 'gift',
        channelId: '42',
        eventId: 'p2',
        at: _sent,
        username: 'Fan',
        recipients: const ['a', 'b', 'c'],
      )!;
      expect(gift.amount!.value, 3);
      final host = kickActivityFromPusher(
        kind: 'host',
        channelId: '42',
        eventId: 'p3',
        at: _sent,
        username: 'Friend',
        viewers: 40,
      )!;
      expect(host.kind, ActivityKind.host);
      expect(host.isBig, isFalse);
    });
  });
}
