import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';

Map<String, Object?> fixture(String name) =>
    json.decode(
          File('test/chat/fixtures/youtube/$name.json').readAsStringSync(),
        )
        as Map<String, Object?>;

void main() {
  group('YouTubeChatMessage fixtures', () {
    test('textMessageEvent parses with author + badges', () {
      final message = YouTubeChatMessage.fromJson(
        fixture('text_message_event'),
      );

      expect(
        message.id,
        'LCC.ChwKHzBtaWQtYWJjZGVmZ2hpamtsbW5vcBIBCXRleHQtbXNnLTE',
      );
      expect(message.type, YouTubeChatMessageType.textMessage);
      expect(message.displayText, 'hello from live chat!');
      expect(
        message.snippet.textMessageDetails?.messageText,
        'hello from live chat!',
      );
      expect(message.authorChannelId, 'UCChatterOne');
      expect(message.authorName, 'Chatter One');
      expect(message.authorProfileImageUrl, contains('chatter-one'));
      expect(message.publishedAt, DateTime.utc(2026, 9, 3, 10, 15, 30));
      expect(message.isSponsor, isTrue);
      expect(message.isOwner, isFalse);
      expect(message.isModerator, isFalse);
      expect(message.isVerified, isFalse);
      expect(message.isTombstoned, isFalse);
    });

    test('superChatEvent parses amount / tier / comment', () {
      final message = YouTubeChatMessage.fromJson(fixture('super_chat_event'));

      expect(message.type, YouTubeChatMessageType.superChat);
      expect(message.snippet.superChatDetails?.amountDisplayString, '\$5.00');
      expect(message.snippet.superChatDetails?.currency, 'USD');
      expect(message.snippet.superChatDetails?.amountMicros, '5000000');
      expect(message.snippet.superChatDetails?.tier, 2);
      expect(
        message.snippet.superChatDetails?.userComment,
        'Great stream, keep it up!',
      );
    });

    test('superStickerEvent parses sticker alt text', () {
      final message = YouTubeChatMessage.fromJson(
        fixture('super_sticker_event'),
      );

      expect(message.type, YouTubeChatMessageType.superSticker);
      final metadata =
          message.snippet.superStickerDetails?.superStickerMetadata;
      expect(metadata?.stickerId, 'sticker-lemon-cat-01');
      expect(metadata?.altText, 'A lemon cat waving hello');
      expect(message.snippet.superStickerDetails?.amountDisplayString, '€1.99');
      expect(message.snippet.superStickerDetails?.tier, 1);
    });

    test('memberMilestoneChatEvent parses month + level', () {
      final message = YouTubeChatMessage.fromJson(
        fixture('member_milestone_chat_event'),
      );

      expect(message.type, YouTubeChatMessageType.memberMilestone);
      expect(message.snippet.memberMilestoneChatDetails?.memberMonth, 6);
      expect(
        message.snippet.memberMilestoneChatDetails?.memberLevelName,
        'Gold Member',
      );
      expect(
        message.snippet.memberMilestoneChatDetails?.userComment,
        '6 months already, wow!',
      );
    });

    test('membershipGiftingEvent parses count + level', () {
      final message = YouTubeChatMessage.fromJson(
        fixture('membership_gifting_event'),
      );

      expect(message.type, YouTubeChatMessageType.membershipGifting);
      expect(message.snippet.membershipGiftingDetails?.giftMembershipsCount, 5);
      expect(
        message.snippet.membershipGiftingDetails?.giftMembershipsLevelName,
        'Gold Member',
      );
    });

    test('pollEvent parses question / options / status', () {
      final message = YouTubeChatMessage.fromJson(fixture('poll_event'));

      expect(message.type, YouTubeChatMessageType.poll);
      final metadata = message.snippet.pollDetails?.metadata;
      expect(metadata?.questionText, 'Which game next?');
      expect(metadata?.status, 'active');
      expect(metadata?.options, hasLength(2));
      expect(metadata?.options.first.optionText, 'Minecraft');
      expect(metadata?.options.first.tally, '42');
      expect(message.isOwner, isTrue);
      expect(message.isVerified, isTrue);
    });

    test(
      'userBannedEvent parses banned user + duration; author is the mod',
      () {
        final message = YouTubeChatMessage.fromJson(
          fixture('user_banned_event'),
        );

        expect(message.type, YouTubeChatMessageType.userBanned);
        expect(message.authorChannelId, 'UCModeratorOne');
        expect(message.isModerator, isTrue);
        final banned = message.snippet.userBannedDetails;
        expect(banned?.banType, 'temporary');
        expect(banned?.banDurationSeconds, 300);
        expect(banned?.bannedUserDetails?.channelId, 'UCTrollUser');
        expect(banned?.bannedUserDetails?.displayName, 'Troll User');
      },
    );

    test(
      'tombstone parses the stripped resource (id of the deleted message)',
      () {
        final message = YouTubeChatMessage.fromJson(fixture('tombstone'));

        expect(message.type, YouTubeChatMessageType.tombstone);

        /// A tombstone reuses the deleted message's id and publishedAt.
        expect(message.id, fixture('text_message_event')['id']);
        expect(message.publishedAt, DateTime.utc(2026, 9, 3, 10, 15, 30));
        expect(message.displayText, isNull);
        expect(message.authorChannelId, isNull);
        expect(message.authorDetails, isNull);
        expect(message.authorName, isNull);
        expect(message.isModerator, isFalse);
      },
    );
  });

  group('YouTubeChatMessageType', () {
    test('unknown types fall back to unknown (forward compat)', () {
      expect(
        YouTubeChatMessageType.parse('giftEvent'),
        YouTubeChatMessageType.unknown,
      );
      expect(
        YouTubeChatMessageType.parse('fanFundingEvent'),
        YouTubeChatMessageType.unknown,
      );
      expect(
        YouTubeChatMessageType.parse('brandNewGoogleType'),
        YouTubeChatMessageType.unknown,
      );
      expect(
        YouTubeChatMessageType.parse(null),
        YouTubeChatMessageType.unknown,
      );
    });

    test('all documented types map to their enum value', () {
      const expected = {
        'textMessageEvent': YouTubeChatMessageType.textMessage,
        'superChatEvent': YouTubeChatMessageType.superChat,
        'superStickerEvent': YouTubeChatMessageType.superSticker,
        'newSponsorEvent': YouTubeChatMessageType.newSponsor,
        'memberMilestoneChatEvent': YouTubeChatMessageType.memberMilestone,
        'membershipGiftingEvent': YouTubeChatMessageType.membershipGifting,
        'giftMembershipReceivedEvent':
            YouTubeChatMessageType.giftMembershipReceived,
        'pollEvent': YouTubeChatMessageType.poll,
        'userBannedEvent': YouTubeChatMessageType.userBanned,
        'tombstone': YouTubeChatMessageType.tombstone,
        'sponsorOnlyModeStartedEvent':
            YouTubeChatMessageType.sponsorOnlyModeStarted,
        'sponsorOnlyModeEndedEvent':
            YouTubeChatMessageType.sponsorOnlyModeEnded,
        'chatEndedEvent': YouTubeChatMessageType.chatEnded,
      };
      expected.forEach((type, expectedValue) {
        expect(YouTubeChatMessageType.parse(type), expectedValue, reason: type);
      });
    });

    test('a resource with an unknown type still parses', () {
      final message = YouTubeChatMessage.fromJson({
        'id': 'msg-x',
        'snippet': {
          'type': 'giftEvent',
          'liveChatId': 'chat-1',
          'publishedAt': '2026-09-03T10:00:00.000Z',
          'hasDisplayContent': true,
          'displayMessage': 'sent a gift',
        },
      });
      expect(message.type, YouTubeChatMessageType.unknown);
      expect(message.displayText, 'sent a gift');
    });
  });

  group('isTombstoned', () {
    test('is local-only — not read from JSON, defaults to false', () {
      final json = fixture('text_message_event');
      json['isTombstoned'] = true;

      final message = YouTubeChatMessage.fromJson(json);

      expect(message.isTombstoned, isFalse);
    });

    test('copyWith flips the local flag', () {
      final message = YouTubeChatMessage.fromJson(
        fixture('text_message_event'),
      );
      final tombstoned = message.copyWith(isTombstoned: true);

      expect(tombstoned.isTombstoned, isTrue);
      expect(message.isTombstoned, isFalse);
    });
  });
}
