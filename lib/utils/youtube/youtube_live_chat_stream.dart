/// `liveChatMessages.streamList` - Google's push read of a live chat
/// (gRPC server streaming, `V3DataLiveChatMessageService.StreamList` on
/// `youtube.googleapis.com:443`). 5 quota units per **call**, like one
/// `liveChatMessages.list` poll, but a call stays open and carries every
/// message until the server closes it - see
/// `docs/youtube-native-chat-audit.md` § Read and
/// `docs/superpowers/specs/2026-10-19-youtube-chat-quota-design.md`.
///
/// gRPC only: the method isn't in the REST discovery doc. The proto is
/// vendored in `stream_list/` (from Google's streaming guide, regenerate
/// with `tool/youtube_spike/setup.sh`).
library;

import 'dart:async';

import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import '../../types/classes/youtube/youtube_chat_message.dart';
import 'stream_list/stream_list.pbgrpc.dart';
import 'youtube_live_chat_service.dart';

/// The stream can't serve this chat right now (permission, key, rate
/// limit, quota, unknown chat, gRPC not answered as expected) - read it
/// with `liveChatMessages.list` instead, whose answers say what's wrong.
class YouTubeStreamFallbackException extends YouTubeApiException {
  const YouTubeStreamFallbackException(super.message, {super.cause});
}

/// The connection dropped before or while streaming (no network, server
/// went away) - connect again, resuming from the last page token.
class YouTubeStreamDroppedException extends YouTubeApiException {
  const YouTubeStreamDroppedException(super.message, {super.cause});
}

/// Opens one streamList call. A fresh [ClientChannel] per call: iOS takes
/// a suspended app's sockets away, and a pooled HTTP/2 connection is what
/// broke the REST reads then (see `RenewingHttpClient`). Calls are rare -
/// one per connection the server keeps open.
class YouTubeLiveChatStreamer {
  static const String host = 'youtube.googleapis.com';

  /// A server stream never writes, so a connection that died quietly
  /// (dead zone, a socket iOS took away) would leave the chat looking
  /// connected but frozen - HTTP/2 pings notice within ~50 s and fail the
  /// call, which reconnects. 30 s is what Google's own streaming client
  /// libraries ping at (a server that minds answers GOAWAY
  /// `too_many_pings` - the spike logs it, see the audit).
  static const ClientKeepAliveOptions keepAlive = ClientKeepAliveOptions(
    pingInterval: Duration(seconds: 30),
    timeout: Duration(seconds: 20),
  );

  /// Pages of [liveChatId] as they arrive, starting after [pageToken]
  /// (null: recent history first). [onOpen] runs once Google accepted the
  /// call (its response headers) - from then on the call is billed.
  /// Ends when the server closes the call; errors are
  /// [YouTubeChatEndedException], [YouTubeStreamFallbackException] or
  /// [YouTubeStreamDroppedException]. Cancelling the subscription closes
  /// the call.
  Stream<YouTubeLiveChatPage> stream(
    String liveChatId,
    String? pageToken, {
    String? apiKey,
    String? accessToken,
    void Function()? onOpen,
  }) {
    late StreamController<YouTubeLiveChatPage> controller;
    ClientChannel? channel;
    ResponseStream<LiveChatMessageListResponse>? call;
    StreamSubscription<LiveChatMessageListResponse>? subscription;

    Future<void> close() async {
      final open = channel;
      channel = null;
      await subscription?.cancel();
      await call?.cancel();
      await open?.shutdown();
    }

    controller = StreamController<YouTubeLiveChatPage>(
      onListen: () {
        final created = ClientChannel(
          host,
          port: 443,
          options: const ChannelOptions(
            credentials: ChannelCredentials.secure(),
            keepAlive: keepAlive,
          ),
        );
        channel = created;
        final request = LiveChatMessageListRequest(
          liveChatId: liveChatId,
          part: const ['id', 'snippet', 'authorDetails'],
        );
        if (pageToken != null) request.pageToken = pageToken;
        final opened = V3DataLiveChatMessageServiceClient(created).streamList(
          request,
          options: CallOptions(
            metadata: {
              if (apiKey != null && apiKey.isNotEmpty) 'x-goog-api-key': apiKey,
              if ((apiKey == null || apiKey.isEmpty) &&
                  accessToken != null &&
                  accessToken.isNotEmpty)
                'authorization': 'Bearer $accessToken',
            },
          ),
        );
        call = opened;

        /// A Trailers-Only error answer completes the headers too - with
        /// its non-zero `grpc-status`
        unawaited(
          opened.headers.then((headers) {
            final status = headers['grpc-status'];
            if (channel != null && (status == null || status == '0')) {
              onOpen?.call();
            }
          }, onError: (_) {}),
        );
        subscription = opened.listen(
          (response) {
            if (!controller.isClosed) {
              controller.add(youTubeChatPageFromProto(response));
            }
          },
          onError: (Object error) {
            if (!controller.isClosed) {
              controller.addError(youTubeStreamErrorFor(error));
              unawaited(controller.close());
            }
            unawaited(close());
          },
          onDone: () {
            if (!controller.isClosed) unawaited(controller.close());
            unawaited(close());
          },
          cancelOnError: true,
        );
      },
      onCancel: close,
    );
    return controller.stream;
  }
}

/// Maps a streamList failure onto the read loop's three answers. Google's
/// table: FAILED_PRECONDITION = chat ended **or** disabled (gRPC can't
/// tell them apart yet), NOT_FOUND = unknown chat, PERMISSION_DENIED,
/// RESOURCE_EXHAUSTED = "faster than the refresh rate" (quota exhaustion
/// may answer the same) - all but ended go to the poll, which tells
/// quota, rate limit and permission apart.
YouTubeApiException youTubeStreamErrorFor(Object error) {
  if (error is! GrpcError) {
    return YouTubeStreamDroppedException(
      'Lost the YouTube chat stream',
      cause: error,
    );
  }
  final message = 'YouTube chat stream: ${error.codeName} (${error.message})';
  switch (error.code) {
    case StatusCode.failedPrecondition:
      return YouTubeChatEndedException(message, cause: error);
    case StatusCode.unavailable:
    case StatusCode.deadlineExceeded:
    case StatusCode.aborted:
    case StatusCode.cancelled:
    case StatusCode.internal:
    case StatusCode.unknown:
      return YouTubeStreamDroppedException(message, cause: error);
    default:
      return YouTubeStreamFallbackException(message, cause: error);
  }
}

/// One streamList answer as a [YouTubeLiveChatPage] - the same page the
/// REST poll gives, built through the REST JSON shape so both reads share
/// [YouTubeChatMessage.fromJson]. The proto differs from the REST JSON in
/// three places: enums are `SCREAMING_CASE` (REST: `textMessageEvent`),
/// a poll's `status` sits on `pollDetails` (REST: `pollDetails.metadata`),
/// and the sticker's `altTextLanguage` is REST's `language`.
YouTubeLiveChatPage youTubeChatPageFromProto(
  LiveChatMessageListResponse response,
) {
  final messages = <YouTubeChatMessage>[];
  for (final item in response.items) {
    final message = _messageFromProto(item);
    if (message != null) messages.add(message);
  }
  return YouTubeLiveChatPage(
    messages: messages,
    nextPageToken: response.hasNextPageToken() ? response.nextPageToken : null,

    /// Not part of the stream - only the poll paces itself
    pollingIntervalMillis: 0,
    offlineAt: response.hasOfflineAt()
        ? DateTime.tryParse(response.offlineAt)
        : null,
    activePollItem: response.hasActivePollItem()
        ? _messageFromProto(response.activePollItem)
        : null,
  );
}

/// Null when Google sent something unreadable (no id / time) - the poll
/// would have failed the whole page on it, the stream skips the row.
YouTubeChatMessage? _messageFromProto(LiveChatMessage item) {
  try {
    return YouTubeChatMessage.fromJson({
      'id': item.id,
      'snippet': _snippetJson(item.snippet),
      if (item.hasAuthorDetails())
        'authorDetails': _authorJson(item.authorDetails),
    });
  } catch (_) {
    return null;
  }
}

/// REST names of the proto's message types - by value, not `.name`:
/// builds may drop protobuf enum names (`protobuf.omit_enum_names`).
/// `fanFundingEvent` / `giftEvent` read as unknown, as from the poll.
String _restType(LiveChatMessageSnippet_TypeWrapper_Type type) =>
    switch (type.value) {
      1 => 'textMessageEvent',
      2 => 'tombstone',
      3 => 'fanFundingEvent',
      4 => 'chatEndedEvent',
      5 => 'sponsorOnlyModeStartedEvent',
      6 => 'sponsorOnlyModeEndedEvent',
      7 => 'newSponsorEvent',
      10 => 'userBannedEvent',
      15 => 'superChatEvent',
      16 => 'superStickerEvent',
      17 => 'memberMilestoneChatEvent',
      18 => 'membershipGiftingEvent',
      19 => 'giftMembershipReceivedEvent',
      20 => 'pollEvent',
      21 => 'giftEvent',
      _ => 'invalidType',
    };

/// 64-bit integers go over REST JSON as strings
String _uint64(Int64 value) => value.toStringUnsigned();

Map<String, Object?> _snippetJson(LiveChatMessageSnippet snippet) => {
  'type': _restType(snippet.type),
  if (snippet.hasLiveChatId()) 'liveChatId': snippet.liveChatId,
  if (snippet.hasAuthorChannelId()) 'authorChannelId': snippet.authorChannelId,
  'publishedAt': snippet.publishedAt,
  'hasDisplayContent': snippet.hasDisplayContent,
  if (snippet.hasDisplayMessage()) 'displayMessage': snippet.displayMessage,
  if (snippet.hasTextMessageDetails())
    'textMessageDetails': {
      'messageText': snippet.textMessageDetails.messageText,
    },
  if (snippet.hasSuperChatDetails())
    'superChatDetails': {
      if (snippet.superChatDetails.hasAmountMicros())
        'amountMicros': _uint64(snippet.superChatDetails.amountMicros),
      if (snippet.superChatDetails.hasCurrency())
        'currency': snippet.superChatDetails.currency,
      if (snippet.superChatDetails.hasAmountDisplayString())
        'amountDisplayString': snippet.superChatDetails.amountDisplayString,
      if (snippet.superChatDetails.hasUserComment())
        'userComment': snippet.superChatDetails.userComment,
      'tier': snippet.superChatDetails.tier,
    },
  if (snippet.hasSuperStickerDetails())
    'superStickerDetails': {
      if (snippet.superStickerDetails.hasSuperStickerMetadata())
        'superStickerMetadata': _stickerJson(
          snippet.superStickerDetails.superStickerMetadata,
        ),
      if (snippet.superStickerDetails.hasAmountMicros())
        'amountMicros': _uint64(snippet.superStickerDetails.amountMicros),
      if (snippet.superStickerDetails.hasCurrency())
        'currency': snippet.superStickerDetails.currency,
      if (snippet.superStickerDetails.hasAmountDisplayString())
        'amountDisplayString': snippet.superStickerDetails.amountDisplayString,
      'tier': snippet.superStickerDetails.tier,
    },
  if (snippet.hasNewSponsorDetails())
    'newSponsorDetails': {
      if (snippet.newSponsorDetails.hasMemberLevelName())
        'memberLevelName': snippet.newSponsorDetails.memberLevelName,
      'isUpgrade': snippet.newSponsorDetails.isUpgrade,
    },
  if (snippet.hasMemberMilestoneChatDetails())
    'memberMilestoneChatDetails': {
      if (snippet.memberMilestoneChatDetails.hasUserComment())
        'userComment': snippet.memberMilestoneChatDetails.userComment,
      'memberMonth': snippet.memberMilestoneChatDetails.memberMonth,
      if (snippet.memberMilestoneChatDetails.hasMemberLevelName())
        'memberLevelName': snippet.memberMilestoneChatDetails.memberLevelName,
    },
  if (snippet.hasMembershipGiftingDetails())
    'membershipGiftingDetails': {
      'giftMembershipsCount':
          snippet.membershipGiftingDetails.giftMembershipsCount,
      if (snippet.membershipGiftingDetails.hasGiftMembershipsLevelName())
        'giftMembershipsLevelName':
            snippet.membershipGiftingDetails.giftMembershipsLevelName,
    },
  if (snippet.hasGiftMembershipReceivedDetails())
    'giftMembershipReceivedDetails': {
      if (snippet.giftMembershipReceivedDetails.hasMemberLevelName())
        'memberLevelName':
            snippet.giftMembershipReceivedDetails.memberLevelName,
      if (snippet.giftMembershipReceivedDetails.hasGifterChannelId())
        'gifterChannelId':
            snippet.giftMembershipReceivedDetails.gifterChannelId,
      if (snippet.giftMembershipReceivedDetails
          .hasAssociatedMembershipGiftingMessageId())
        'associatedMembershipGiftingMessageId': snippet
            .giftMembershipReceivedDetails
            .associatedMembershipGiftingMessageId,
    },
  if (snippet.hasPollDetails())
    'pollDetails': {
      'metadata': {
        if (snippet.pollDetails.metadata.hasQuestionText())
          'questionText': snippet.pollDetails.metadata.questionText,
        'options': [
          for (final option in snippet.pollDetails.metadata.options)
            {
              if (option.hasOptionText()) 'optionText': option.optionText,
              if (option.hasTally()) 'tally': option.tally.toString(),
            },
        ],
        if (snippet.pollDetails.hasStatus())
          'status': switch (snippet.pollDetails.status.value) {
            1 => 'active',
            2 => 'closed',
            _ => 'unknown',
          },
      },
    },
  if (snippet.hasUserBannedDetails())
    'userBannedDetails': {
      if (snippet.userBannedDetails.hasBannedUserDetails())
        'bannedUserDetails': {
          if (snippet.userBannedDetails.bannedUserDetails.hasChannelId())
            'channelId': snippet.userBannedDetails.bannedUserDetails.channelId,
          if (snippet.userBannedDetails.bannedUserDetails.hasChannelUrl())
            'channelUrl':
                snippet.userBannedDetails.bannedUserDetails.channelUrl,
          if (snippet.userBannedDetails.bannedUserDetails.hasDisplayName())
            'displayName':
                snippet.userBannedDetails.bannedUserDetails.displayName,
          if (snippet.userBannedDetails.bannedUserDetails.hasProfileImageUrl())
            'profileImageUrl':
                snippet.userBannedDetails.bannedUserDetails.profileImageUrl,
        },
      if (snippet.userBannedDetails.hasBanType())
        'banType': snippet.userBannedDetails.banType.value == 2
            ? 'temporary'
            : 'permanent',
      if (snippet.userBannedDetails.hasBanDurationSeconds())
        'banDurationSeconds': _uint64(
          snippet.userBannedDetails.banDurationSeconds,
        ),
    },
};

Map<String, Object?> _stickerJson(SuperStickerMetadata sticker) => {
  if (sticker.hasStickerId()) 'stickerId': sticker.stickerId,
  if (sticker.hasAltText()) 'altText': sticker.altText,
  if (sticker.hasAltTextLanguage()) 'language': sticker.altTextLanguage,
};

Map<String, Object?> _authorJson(LiveChatMessageAuthorDetails author) => {
  if (author.hasChannelId()) 'channelId': author.channelId,
  if (author.hasChannelUrl()) 'channelUrl': author.channelUrl,
  if (author.hasDisplayName()) 'displayName': author.displayName,
  if (author.hasProfileImageUrl()) 'profileImageUrl': author.profileImageUrl,
  'isVerified': author.isVerified,
  'isChatOwner': author.isChatOwner,
  'isChatSponsor': author.isChatSponsor,
  'isChatModerator': author.isChatModerator,
};
