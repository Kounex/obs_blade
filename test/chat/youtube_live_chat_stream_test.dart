import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/utils/youtube/stream_list/stream_list.pb.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_stream.dart';

/// streamList answers mapped onto the poll's page / message model. Shapes
/// follow Google's `stream_list.proto` (vendored in
/// `lib/utils/youtube/stream_list/`): enums by value, 64-bit ints as
/// `Int64`, a poll's status on `pollDetails`, the sticker's
/// `altTextLanguage`.
void main() {
  LiveChatMessage message(
    String id,
    LiveChatMessageSnippet snippet, {
    LiveChatMessageAuthorDetails? author,
  }) => LiveChatMessage(id: id, snippet: snippet, authorDetails: author);

  LiveChatMessageSnippet snippet(
    LiveChatMessageSnippet_TypeWrapper_Type type, {
    String? display,
  }) => LiveChatMessageSnippet(
    type: type,
    liveChatId: 'chat-1',
    authorChannelId: 'UCauthor',
    publishedAt: '2026-10-19T12:00:00Z',
    hasDisplayContent: display != null,
    displayMessage: display,
  );

  group('youTubeChatPageFromProto', () {
    test('page fields: token, offlineAt, rows in order', () {
      final page = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          nextPageToken: 'next-1',
          offlineAt: '2026-10-19T14:00:00Z',
          items: [
            message(
              'a',
              snippet(
                  LiveChatMessageSnippet_TypeWrapper_Type.TEXT_MESSAGE_EVENT,
                  display: 'hi',
                )
                ..textMessageDetails = LiveChatTextMessageDetails(
                  messageText: 'hi',
                ),
            ),
            message(
              'b',
              snippet(LiveChatMessageSnippet_TypeWrapper_Type.TOMBSTONE),
            ),
          ],
        ),
      );
      expect(page.nextPageToken, 'next-1');
      expect(page.offlineAt, DateTime.utc(2026, 10, 19, 14));
      expect(page.messages.map((m) => m.id), ['a', 'b']);
      expect(page.messages.first.type, YouTubeChatMessageType.textMessage);
      expect(page.messages.first.copyText, 'hi');
      expect(page.messages.last.type, YouTubeChatMessageType.tombstone);
      expect(page.activePollItem, isNull);
    });

    test('author details and badges', () {
      final page = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            message(
              'a',
              snippet(
                LiveChatMessageSnippet_TypeWrapper_Type.TEXT_MESSAGE_EVENT,
                display: 'yo',
              ),
              author: LiveChatMessageAuthorDetails(
                channelId: 'UCauthor',
                displayName: 'Some One',
                profileImageUrl: 'https://yt3.example/a.jpg',
                isChatModerator: true,
                isChatSponsor: true,
              ),
            ),
          ],
        ),
      );
      final row = page.messages.single;
      expect(row.authorName, 'Some One');
      expect(row.authorProfileImageUrl, 'https://yt3.example/a.jpg');
      expect(row.isModerator, isTrue);
      expect(row.isSponsor, isTrue);
      expect(row.isOwner, isFalse);
    });

    test('Super Chat: 64-bit amount as the REST string, tier', () {
      final row = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            message(
              's',
              snippet(
                  LiveChatMessageSnippet_TypeWrapper_Type.SUPER_CHAT_EVENT,
                  display: r'$5.00 from Some One',
                )
                ..superChatDetails = LiveChatSuperChatDetails(
                  amountMicros: Int64(5000000),
                  currency: 'USD',
                  amountDisplayString: r'$5.00',
                  userComment: 'great stream',
                  tier: 2,
                ),
            ),
          ],
        ),
      ).messages.single;
      expect(row.type, YouTubeChatMessageType.superChat);
      final details = row.snippet.superChatDetails!;
      expect(details.amountMicros, '5000000');
      expect(details.amountDisplayString, r'$5.00');
      expect(details.userComment, 'great stream');
      expect(details.tier, 2);
    });

    test('Super Sticker: alt text language lands in `language`', () {
      final row = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            message(
              's',
              snippet(
                  LiveChatMessageSnippet_TypeWrapper_Type.SUPER_STICKER_EVENT,
                )
                ..superStickerDetails = LiveChatSuperStickerDetails(
                  tier: 1,
                  superStickerMetadata: SuperStickerMetadata(
                    stickerId: 'cat',
                    altText: 'A cat waving',
                    altTextLanguage: 'en',
                  ),
                ),
            ),
          ],
        ),
      ).messages.single;
      final sticker = row.snippet.superStickerDetails!.superStickerMetadata!;
      expect(sticker.altText, 'A cat waving');
      expect(sticker.language, 'en');
    });

    test('timeout: ban type and duration as the REST strings', () {
      final row = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            message(
              'ban',
              snippet(LiveChatMessageSnippet_TypeWrapper_Type.USER_BANNED_EVENT)
                ..userBannedDetails = LiveChatUserBannedMessageDetails(
                  banType:
                      LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType
                          .TEMPORARY,
                  banDurationSeconds: Int64(300),
                  bannedUserDetails: ChannelProfileDetails(
                    channelId: 'UCbanned',
                    displayName: 'Troll',
                  ),
                ),
            ),
          ],
        ),
      ).messages.single;
      final ban = row.snippet.userBannedDetails!;
      expect(row.type, YouTubeChatMessageType.userBanned);
      expect(ban.banType, 'temporary');
      expect(ban.banDurationSeconds, 300);
      expect(ban.bannedUserDetails?.channelId, 'UCbanned');
    });

    test('poll: status moves under metadata, tallies as strings; '
        'activePollItem maps too', () {
      LiveChatMessage poll(
        LiveChatPollDetails_PollStatusWrapper_PollStatus status,
      ) => message(
        'poll-1',
        snippet(LiveChatMessageSnippet_TypeWrapper_Type.POLL_EVENT)
          ..pollDetails = LiveChatPollDetails(
            status: status,
            metadata: LiveChatPollDetails_PollMetadata(
              questionText: 'Next game?',
              options: [
                LiveChatPollDetails_PollMetadata_PollOption(
                  optionText: 'A',
                  tally: Int64(3),
                ),
                LiveChatPollDetails_PollMetadata_PollOption(optionText: 'B'),
              ],
            ),
          ),
      );
      final page = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            poll(LiveChatPollDetails_PollStatusWrapper_PollStatus.CLOSED),
          ],
          activePollItem: poll(
            LiveChatPollDetails_PollStatusWrapper_PollStatus.ACTIVE,
          ),
        ),
      );
      final closed = page.messages.single.snippet.pollDetails!.metadata!;
      expect(page.messages.single.type, YouTubeChatMessageType.poll);
      expect(closed.status, 'closed');
      expect(closed.questionText, 'Next game?');
      expect(closed.options.map((o) => o.tally), ['3', null]);
      expect(
        page.activePollItem?.snippet.pollDetails?.metadata?.status,
        'active',
      );
    });

    test('membership rows', () {
      final rows = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            message(
              'm1',
              snippet(LiveChatMessageSnippet_TypeWrapper_Type.NEW_SPONSOR_EVENT)
                ..newSponsorDetails = LiveChatNewSponsorDetails(
                  memberLevelName: 'Gold',
                  isUpgrade: true,
                ),
            ),
            message(
              'm2',
              snippet(
                  LiveChatMessageSnippet_TypeWrapper_Type
                      .MEMBER_MILESTONE_CHAT_EVENT,
                )
                ..memberMilestoneChatDetails =
                    LiveChatMemberMilestoneChatDetails(
                      memberMonth: 12,
                      userComment: 'a year!',
                    ),
            ),
            message(
              'm3',
              snippet(
                  LiveChatMessageSnippet_TypeWrapper_Type
                      .MEMBERSHIP_GIFTING_EVENT,
                )
                ..membershipGiftingDetails = LiveChatMembershipGiftingDetails(
                  giftMembershipsCount: 5,
                ),
            ),
            message(
              'm4',
              snippet(
                  LiveChatMessageSnippet_TypeWrapper_Type
                      .GIFT_MEMBERSHIP_RECEIVED_EVENT,
                )
                ..giftMembershipReceivedDetails =
                    LiveChatGiftMembershipReceivedDetails(
                      gifterChannelId: 'UCgifter',
                      associatedMembershipGiftingMessageId: 'm3',
                    ),
            ),
          ],
        ),
      ).messages;
      expect(rows.map((m) => m.type), [
        YouTubeChatMessageType.newSponsor,
        YouTubeChatMessageType.memberMilestone,
        YouTubeChatMessageType.membershipGifting,
        YouTubeChatMessageType.giftMembershipReceived,
      ]);
      expect(rows[0].snippet.newSponsorDetails?.isUpgrade, isTrue);
      expect(rows[1].snippet.memberMilestoneChatDetails?.memberMonth, 12);
      expect(rows[2].snippet.membershipGiftingDetails?.giftMembershipsCount, 5);
      expect(
        rows[3].snippet.giftMembershipReceivedDetails?.gifterChannelId,
        'UCgifter',
      );
    });

    test('chat ended and types the poll read doesn\'t know either', () {
      final rows = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            message(
              'g',
              snippet(LiveChatMessageSnippet_TypeWrapper_Type.GIFT_EVENT),
            ),
            message(
              'e',
              snippet(LiveChatMessageSnippet_TypeWrapper_Type.CHAT_ENDED_EVENT),
            ),
          ],
        ),
      ).messages;
      expect(rows.map((m) => m.type), [
        YouTubeChatMessageType.unknown,
        YouTubeChatMessageType.chatEnded,
      ]);
    });

    test('an unreadable row (no time) is skipped, not the whole page', () {
      final page = youTubeChatPageFromProto(
        LiveChatMessageListResponse(
          items: [
            LiveChatMessage(
              id: 'broken',
              snippet: LiveChatMessageSnippet(
                type:
                    LiveChatMessageSnippet_TypeWrapper_Type.TEXT_MESSAGE_EVENT,
              ),
            ),
            message(
              'ok',
              snippet(
                LiveChatMessageSnippet_TypeWrapper_Type.TEXT_MESSAGE_EVENT,
                display: 'fine',
              ),
            ),
          ],
        ),
      );
      expect(page.messages.map((m) => m.id), ['ok']);
    });
  });

  group('youTubeStreamErrorFor', () {
    for (final (name, error, type) in [
      (
        'FAILED_PRECONDITION: chat ended (or disabled)',
        GrpcError.failedPrecondition('LIVE_CHAT_ENDED'),
        YouTubeChatEndedException,
      ),
      (
        'UNAVAILABLE: dropped, reconnect',
        GrpcError.unavailable('Did not receive anything'),
        YouTubeStreamDroppedException,
      ),
      (
        'DEADLINE_EXCEEDED: dropped',
        GrpcError.deadlineExceeded('slow'),
        YouTubeStreamDroppedException,
      ),
      (
        'RESOURCE_EXHAUSTED: rate limit or quota - the poll tells',
        GrpcError.resourceExhausted('Resource has been exhausted'),
        YouTubeStreamFallbackException,
      ),
      (
        'PERMISSION_DENIED: the poll explains it',
        GrpcError.permissionDenied('The caller does not have permission'),
        YouTubeStreamFallbackException,
      ),
      (
        'NOT_FOUND: the poll explains it',
        GrpcError.notFound('Requested entity was not found'),
        YouTubeStreamFallbackException,
      ),
      (
        'UNIMPLEMENTED: no stream here',
        GrpcError.unimplemented('nope'),
        YouTubeStreamFallbackException,
      ),
      (
        'a socket error: dropped',
        const SocketException('Network is unreachable'),
        YouTubeStreamDroppedException,
      ),
    ]) {
      test(name, () => expect(youTubeStreamErrorFor(error).runtimeType, type));
    }
  });
}
