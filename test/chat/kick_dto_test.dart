import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';

/// Live `ChatMessageEvent` payload captured verbatim from
/// `chatrooms.{id}.v2` (2026-09-22).
const capturedMessage = <String, Object?>{
  'id': 'b3fd8da8-1111-2222-3333-444455556666',
  'chatroom_id': 5389830,
  'content': 'ong',
  'type': 'message',
  'created_at': '2026-09-22T12:04:49+00:00',
  'sender': <String, Object?>{
    'id': 121500917,
    'username': 'RealDebt',
    'slug': 'realdebd',
    'identity': <String, Object?>{
      'color': '#FFAE76',
      'badges': <Object?>[],
      'badges_v2': <Object?>[
        <String, Object?>{
          'name': 'level',
          'badge_type': 'global',
          'image_url': 'https://ext.cdn.kick.com/chat/badges/32_level.png',
          'metadata': <String, Object?>{'level': 32},
          'selected': true,
          'sort_order': 1,
        },
      ],
    },
  },
  'metadata': <String, Object?>{'message_ref': '1790078688724'},
};

void main() {
  group('KickChatMessage', () {
    test('parses the captured live payload verbatim', () {
      final message = KickChatMessage.fromJson(capturedMessage);

      expect(message.id, 'b3fd8da8-1111-2222-3333-444455556666');
      expect(message.chatroomId, 5389830);
      expect(message.content, 'ong');
      expect(message.type, KickChatMessageType.message);
      expect(message.createdAt, DateTime.utc(2026, 9, 22, 12, 4, 49));
      expect(message.authorName, 'RealDebt');
      expect(message.authorId, 121500917);
      expect(message.sender?.identity?.color, '#FFAE76');
      expect(message.isTombstoned, isFalse);

      final badges = message.sender!.identity!.displayBadges;
      expect(badges, hasLength(1));
      expect(badges.single.name, 'level');
      expect(badges.single.imageUrl, endsWith('32_level.png'));
      expect(badges.single.metadata?['level'], 32);
      expect(message.metadata?.messageRef, '1790078688724');
    });

    test('tolerates metadata as a JSON-encoded string (backfill shape)', () {
      final message = KickChatMessage.fromJson(<String, Object?>{
        ...capturedMessage,
        'metadata': json.encode(<String, Object?>{
          'message_ref': '1790078688724',
        }),
      });

      expect(message.metadata?.messageRef, '1790078688724');
    });

    test('junk metadata (non-JSON string) degrades to null', () {
      final message = KickChatMessage.fromJson(<String, Object?>{
        ...capturedMessage,
        'metadata': 'not json at all',
      });

      expect(message.metadata, isNull);
    });

    test('reply messages flatten original_sender / original_message, both '
        'shapes', () {
      final nested = KickChatMessage.fromJson(<String, Object?>{
        ...capturedMessage,
        'type': 'reply',
        'metadata': <String, Object?>{
          'message_ref': 'ref',
          'original_sender': <String, Object?>{'username': 'OriginalUser'},
          'original_message': <String, Object?>{'content': 'the first take'},
        },
      });
      expect(nested.type, KickChatMessageType.reply);
      expect(nested.metadata?.originalSenderName, 'OriginalUser');
      expect(nested.metadata?.originalMessageContent, 'the first take');

      final flat = KickChatMessage.fromJson(<String, Object?>{
        ...capturedMessage,
        'type': 'reply',
        'metadata': <String, Object?>{
          'original_sender': 'OriginalUser',
          'original_message': 'the first take',
        },
      });
      expect(flat.metadata?.originalSenderName, 'OriginalUser');
      expect(flat.metadata?.originalMessageContent, 'the first take');
    });

    test('legacy badges parse (type / text / count)', () {
      final message = KickChatMessage.fromJson(<String, Object?>{
        ...capturedMessage,
        'sender': <String, Object?>{
          'id': 1,
          'username': 'Legacy',
          'slug': 'legacy',
          'identity': <String, Object?>{
            'color': '#FFFFFF',
            'badges': <Object?>[
              <String, Object?>{
                'type': 'subscriber',
                'text': 'Subscriber',
                'count': 7,
              },
            ],
          },
        },
      });

      final identity = message.sender!.identity!;
      expect(identity.badges.single.type, 'subscriber');
      expect(identity.badges.single.text, 'Subscriber');
      expect(identity.badges.single.count, 7);

      /// No v2 artwork → the legacy chips are the fallback the row
      /// renders.
      expect(identity.displayBadges, isEmpty);
    });

    test('displayBadges falls back to all artwork-bearing v2 badges when '
        'none is selected', () {
      final message = KickChatMessage.fromJson(<String, Object?>{
        ...capturedMessage,
        'sender': <String, Object?>{
          'id': 1,
          'username': 'Multi',
          'slug': 'multi',
          'identity': <String, Object?>{
            'badges_v2': <Object?>[
              <String, Object?>{
                'name': 'a',
                'image_url': 'https://example.com/a.png',
              },
              <String, Object?>{
                'name': 'b',
                'image_url': 'https://example.com/b.png',
              },
              <String, Object?>{'name': 'no-art'},
            ],
          },
        },
      });

      expect(message.sender!.identity!.displayBadges.map((b) => b.name), [
        'a',
        'b',
      ]);
    });
  });

  group('parseKickChatContent', () {
    test('splits text and emote tokens in order', () {
      final fragments = parseKickChatContent(
        'hi [emote:37253:UWU] there [emote:123:pog]',
      );

      expect(fragments, hasLength(4));
      expect(fragments[0].text, 'hi ');
      expect(fragments[1].isEmote, isTrue);
      expect(fragments[1].emoteId, 37253);
      expect(fragments[1].emoteName, 'UWU');
      expect(fragments[2].text, ' there ');
      expect(fragments[3].emoteId, 123);
      expect(
        kickEmoteUrl(37253),
        'https://files.kick.com/emotes/37253/fullsize',
      );
    });

    test('malformed tokens degrade to their raw text; empty stays empty', () {
      expect(parseKickChatContent(''), isEmpty);
      final fragments = parseKickChatContent('[emote:abc:oops]');
      expect(fragments.single.isEmote, isFalse);
      expect(fragments.single.text, '[emote:abc:oops]');
    });
  });

  group('KickChannelInfo', () {
    test('parses the resolution payload (modes, badges, livestream)', () {
      final info = KickChannelInfo.fromJson(<String, Object?>{
        'id': 12345,
        'user_id': 678,
        'slug': 'somechannel',
        'user': <String, Object?>{'username': 'SomeChannel'},
        'chatroom': <String, Object?>{
          'id': 999,
          'slow_mode': true,
          'followers_mode': false,
          'subscribers_mode': false,
          'emotes_mode': false,
          'message_interval': 3,
          'following_min_duration': 0,
        },
        'subscriber_badges': <Object?>[
          <String, Object?>{
            'months': 2,
            'badge_image': <String, Object?>{
              'src': 'https://files.kick.com/badges/sub2.png',
            },
          },
        ],
        'livestream': <String, Object?>{'is_live': true, 'viewer_count': 4321},
      });

      expect(info.id, 12345);
      expect(info.username, 'SomeChannel');
      expect(info.chatroomId, 999);
      expect(info.chatroom.slowMode, isTrue);
      expect(info.chatroom.messageInterval, 3);
      expect(info.subscriberBadges.single.months, 2);
      expect(
        info.subscriberBadges.single.imageUrl,
        'https://files.kick.com/badges/sub2.png',
      );
      expect(info.isLive, isTrue);
      expect(info.viewerCount, 4321);
    });

    test('offline channel: null livestream degrades to not-live', () {
      final info = KickChannelInfo.fromJson(<String, Object?>{
        'id': 1,
        'slug': 'x',
        'chatroom': <String, Object?>{'id': 2},
        'livestream': null,
      });

      expect(info.isLive, isFalse);
      expect(info.viewerCount, isNull);
    });
  });

  group('KickPusherEvent', () {
    test('parses the pusher envelope, decoding the data string', () {
      final event = KickPusherEvent.parse(
        json.encode(<String, Object?>{
          'event': 'App\\Events\\ChatMessageEvent',
          'channel': 'chatrooms.5389830.v2',
          'data': json.encode(capturedMessage),
        }),
      )!;

      expect(event.kind, KickChatroomEventKind.message);
      expect(event.channel, 'chatrooms.5389830.v2');
      expect(event.data['content'], 'ong');
    });

    test('tolerates data as an object (not just a string)', () {
      final event = KickPusherEvent.parse(
        json.encode(<String, Object?>{
          'event': 'pusher:connection_established',
          'data': <String, Object?>{'socket_id': '1.2'},
        }),
      )!;

      expect(event.data['socket_id'], '1.2');
    });

    test('junk frames parse to null', () {
      expect(KickPusherEvent.parse('not json'), isNull);
      expect(KickPusherEvent.parse('{"no_event": true}'), isNull);
      expect(KickPusherEvent.parse('[1,2]'), isNull);
    });

    test('classifies every chatroom event by suffix', () {
      KickChatroomEventKind kindOf(String name) =>
          KickPusherEvent(event: name).kind;

      expect(
        kindOf('App\\Events\\ChatMessageEvent'),
        KickChatroomEventKind.message,
      );
      expect(
        kindOf('App\\Events\\ChatMessageSentEvent'),
        KickChatroomEventKind.message,
      );
      expect(
        kindOf('App\\Events\\MessageDeletedEvent'),
        KickChatroomEventKind.messageDeleted,
      );
      expect(
        kindOf('App\\Events\\UserBannedEvent'),
        KickChatroomEventKind.userBanned,
      );
      expect(
        kindOf('App\\Events\\UserUnbannedEvent'),
        KickChatroomEventKind.userUnbanned,
      );
      expect(
        kindOf('App\\Events\\ChatroomClearEvent'),
        KickChatroomEventKind.chatroomClear,
      );
      expect(
        kindOf('App\\Events\\ChatroomUpdatedEvent'),
        KickChatroomEventKind.chatroomUpdated,
      );
      expect(
        kindOf('App\\Events\\PinnedMessageCreatedEvent'),
        KickChatroomEventKind.pinnedMessage,
      );
      expect(
        kindOf('App\\Events\\PinnedMessageDeletedEvent'),
        KickChatroomEventKind.pinnedMessage,
      );
      expect(
        const KickPusherEvent(
          event: 'App\\Events\\PinnedMessageCreatedEvent',
          data: <String, Object?>{
            'message': <String, Object?>{
              'id': 'pin-1',
              'content': 'rules',
              'sender': <String, Object?>{'username': 'Mod'},
            },
            'pinned_by': <String, Object?>{'username': 'Other'},
          },
        ).pinnedChatMessage?.authorName,
        'Mod',
      );
      expect(
        const KickPusherEvent(
          event: 'App\\Events\\PinnedMessageDeletedEvent',
        ).isPinDeleted,
        isTrue,
      );
      expect(
        kindOf('App\\Events\\SubscriptionEvent'),
        KickChatroomEventKind.subscription,
      );
      expect(
        kindOf('App\\Events\\GiftedSubscriptionsEvent'),
        KickChatroomEventKind.giftedSubscriptions,
      );
      expect(
        kindOf('App\\Events\\StreamHostEvent'),
        KickChatroomEventKind.streamHost,
      );
      expect(
        kindOf('App\\Events\\SomethingElse'),
        KickChatroomEventKind.unknown,
      );
    });

    test('subscriberUsername / subscriptionMonths read the reverse-'
        'engineered SubscriptionEvent shape', () {
      const event = KickPusherEvent(
        event: 'App\\Events\\SubscriptionEvent',
        data: <String, Object?>{'username': 'Loyal', 'months': 6},
      );
      expect(event.subscriberUsername, 'Loyal');
      expect(event.subscriptionMonths, 6);

      const missingField = KickPusherEvent(
        event: 'App\\Events\\SubscriptionEvent',
        data: <String, Object?>{'username': 'Loyal'},
      );
      expect(missingField.subscriptionMonths, isNull);
    });

    test('gifterUsername / giftedUsernames read the reverse-engineered '
        'GiftedSubscriptionsEvent shape', () {
      const event = KickPusherEvent(
        event: 'App\\Events\\GiftedSubscriptionsEvent',
        data: <String, Object?>{
          'gifter_username': 'BigSpender',
          'gifted_usernames': <Object?>['Alice', 'Bob'],
        },
      );
      expect(event.gifterUsername, 'BigSpender');
      expect(event.giftedUsernames, ['Alice', 'Bob']);

      const missing = KickPusherEvent(
        event: 'App\\Events\\GiftedSubscriptionsEvent',
      );
      expect(missing.giftedUsernames, isEmpty);
    });

    test('hostUsername / hostViewerCount / hostMessage read the reverse-'
        'engineered StreamHostEvent shape', () {
      const event = KickPusherEvent(
        event: 'App\\Events\\StreamHostEvent',
        data: <String, Object?>{
          'host_username': 'BigStreamer',
          'number_viewers': 250,
          'optional_message': 'good luck!',
        },
      );
      expect(event.hostUsername, 'BigStreamer');
      expect(event.hostViewerCount, 250);
      expect(event.hostMessage, 'good luck!');
    });

    test('deletedMessageId prefers the nested message id, falls back to '
        'the outer id', () {
      expect(
        const KickPusherEvent(
          event: 'App\\Events\\MessageDeletedEvent',
          data: <String, Object?>{
            'id': 'event-id',
            'message': <String, Object?>{'id': 'message-id'},
          },
        ).deletedMessageId,
        'message-id',
      );
      expect(
        const KickPusherEvent(
          event: 'App\\Events\\MessageDeletedEvent',
          data: <String, Object?>{'id': 'outer-id'},
        ).deletedMessageId,
        'outer-id',
      );
    });

    test('targetUserId reads user.id', () {
      expect(
        const KickPusherEvent(
          event: 'App\\Events\\UserBannedEvent',
          data: <String, Object?>{
            'user': <String, Object?>{'id': 121500917},
          },
        ).targetUserId,
        121500917,
      );
      expect(
        const KickPusherEvent(
          event: 'App\\Events\\UserBannedEvent',
        ).targetUserId,
        isNull,
      );
    });
  });
}
