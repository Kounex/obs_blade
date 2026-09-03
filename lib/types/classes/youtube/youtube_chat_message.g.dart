// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_YouTubeChatMessage _$YouTubeChatMessageFromJson(Map<String, dynamic> json) =>
    _YouTubeChatMessage(
      id: json['id'] as String,
      snippet: YouTubeChatMessageSnippet.fromJson(
        json['snippet'] as Map<String, dynamic>,
      ),
      authorDetails: json['authorDetails'] == null
          ? null
          : YouTubeChatAuthorDetails.fromJson(
              json['authorDetails'] as Map<String, dynamic>,
            ),
    );

_YouTubeChatMessageSnippet _$YouTubeChatMessageSnippetFromJson(
  Map<String, dynamic> json,
) => _YouTubeChatMessageSnippet(
  type: YouTubeChatMessageType.parse(json['type']),
  liveChatId: json['liveChatId'] as String?,
  authorChannelId: json['authorChannelId'] as String?,
  publishedAt: DateTime.parse(json['publishedAt'] as String),
  hasDisplayContent: json['hasDisplayContent'] as bool? ?? false,
  displayMessage: json['displayMessage'] as String?,
  textMessageDetails: json['textMessageDetails'] == null
      ? null
      : YouTubeTextMessageDetails.fromJson(
          json['textMessageDetails'] as Map<String, dynamic>,
        ),
  superChatDetails: json['superChatDetails'] == null
      ? null
      : YouTubeSuperChatDetails.fromJson(
          json['superChatDetails'] as Map<String, dynamic>,
        ),
  superStickerDetails: json['superStickerDetails'] == null
      ? null
      : YouTubeSuperStickerDetails.fromJson(
          json['superStickerDetails'] as Map<String, dynamic>,
        ),
  newSponsorDetails: json['newSponsorDetails'] == null
      ? null
      : YouTubeNewSponsorDetails.fromJson(
          json['newSponsorDetails'] as Map<String, dynamic>,
        ),
  memberMilestoneChatDetails: json['memberMilestoneChatDetails'] == null
      ? null
      : YouTubeMemberMilestoneDetails.fromJson(
          json['memberMilestoneChatDetails'] as Map<String, dynamic>,
        ),
  membershipGiftingDetails: json['membershipGiftingDetails'] == null
      ? null
      : YouTubeMembershipGiftingDetails.fromJson(
          json['membershipGiftingDetails'] as Map<String, dynamic>,
        ),
  giftMembershipReceivedDetails: json['giftMembershipReceivedDetails'] == null
      ? null
      : YouTubeGiftMembershipReceivedDetails.fromJson(
          json['giftMembershipReceivedDetails'] as Map<String, dynamic>,
        ),
  pollDetails: json['pollDetails'] == null
      ? null
      : YouTubePollDetails.fromJson(
          json['pollDetails'] as Map<String, dynamic>,
        ),
  userBannedDetails: json['userBannedDetails'] == null
      ? null
      : YouTubeUserBannedDetails.fromJson(
          json['userBannedDetails'] as Map<String, dynamic>,
        ),
);

_YouTubeChatAuthorDetails _$YouTubeChatAuthorDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeChatAuthorDetails(
  channelId: json['channelId'] as String?,
  channelUrl: json['channelUrl'] as String?,
  displayName: json['displayName'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  isChatOwner: json['isChatOwner'] as bool? ?? false,
  isChatSponsor: json['isChatSponsor'] as bool? ?? false,
  isChatModerator: json['isChatModerator'] as bool? ?? false,
);

_YouTubeTextMessageDetails _$YouTubeTextMessageDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeTextMessageDetails(messageText: json['messageText'] as String);

_YouTubeSuperChatDetails _$YouTubeSuperChatDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeSuperChatDetails(
  amountMicros: json['amountMicros'] as String?,
  currency: json['currency'] as String?,
  amountDisplayString: json['amountDisplayString'] as String?,
  userComment: json['userComment'] as String?,
  tier: (json['tier'] as num?)?.toInt() ?? 0,
);

_YouTubeSuperStickerDetails _$YouTubeSuperStickerDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeSuperStickerDetails(
  superStickerMetadata: json['superStickerMetadata'] == null
      ? null
      : YouTubeSuperStickerMetadata.fromJson(
          json['superStickerMetadata'] as Map<String, dynamic>,
        ),
  amountMicros: json['amountMicros'] as String?,
  currency: json['currency'] as String?,
  amountDisplayString: json['amountDisplayString'] as String?,
  tier: (json['tier'] as num?)?.toInt() ?? 0,
);

_YouTubeSuperStickerMetadata _$YouTubeSuperStickerMetadataFromJson(
  Map<String, dynamic> json,
) => _YouTubeSuperStickerMetadata(
  stickerId: json['stickerId'] as String?,
  altText: json['altText'] as String?,
  language: json['language'] as String?,
);

_YouTubeNewSponsorDetails _$YouTubeNewSponsorDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeNewSponsorDetails(
  memberLevelName: json['memberLevelName'] as String?,
  isUpgrade: json['isUpgrade'] as bool? ?? false,
);

_YouTubeMemberMilestoneDetails _$YouTubeMemberMilestoneDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeMemberMilestoneDetails(
  userComment: json['userComment'] as String?,
  memberMonth: (json['memberMonth'] as num?)?.toInt() ?? 0,
  memberLevelName: json['memberLevelName'] as String?,
);

_YouTubeMembershipGiftingDetails _$YouTubeMembershipGiftingDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeMembershipGiftingDetails(
  giftMembershipsCount: (json['giftMembershipsCount'] as num?)?.toInt() ?? 0,
  giftMembershipsLevelName: json['giftMembershipsLevelName'] as String?,
);

_YouTubeGiftMembershipReceivedDetails
_$YouTubeGiftMembershipReceivedDetailsFromJson(Map<String, dynamic> json) =>
    _YouTubeGiftMembershipReceivedDetails(
      memberLevelName: json['memberLevelName'] as String?,
      gifterChannelId: json['gifterChannelId'] as String?,
      associatedMembershipGiftingMessageId:
          json['associatedMembershipGiftingMessageId'] as String?,
    );

_YouTubePollDetails _$YouTubePollDetailsFromJson(Map<String, dynamic> json) =>
    _YouTubePollDetails(
      metadata: json['metadata'] == null
          ? null
          : YouTubePollMetadata.fromJson(
              json['metadata'] as Map<String, dynamic>,
            ),
    );

_YouTubePollMetadata _$YouTubePollMetadataFromJson(Map<String, dynamic> json) =>
    _YouTubePollMetadata(
      questionText: json['questionText'] as String?,
      options:
          (json['options'] as List<dynamic>?)
              ?.map(
                (e) => YouTubePollOption.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <YouTubePollOption>[],
      status: json['status'] as String?,
    );

_YouTubePollOption _$YouTubePollOptionFromJson(Map<String, dynamic> json) =>
    _YouTubePollOption(
      optionText: json['optionText'] as String?,
      tally: json['tally'] as String?,
    );

_YouTubeUserBannedDetails _$YouTubeUserBannedDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeUserBannedDetails(
  bannedUserDetails: json['bannedUserDetails'] == null
      ? null
      : YouTubeBannedUserDetails.fromJson(
          json['bannedUserDetails'] as Map<String, dynamic>,
        ),
  banType: json['banType'] as String?,
  banDurationSeconds: (json['banDurationSeconds'] as num?)?.toInt(),
);

_YouTubeBannedUserDetails _$YouTubeBannedUserDetailsFromJson(
  Map<String, dynamic> json,
) => _YouTubeBannedUserDetails(
  channelId: json['channelId'] as String?,
  channelUrl: json['channelUrl'] as String?,
  displayName: json['displayName'] as String?,
  profileImageUrl: json['profileImageUrl'] as String?,
);
