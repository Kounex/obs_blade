import 'package:freezed_annotation/freezed_annotation.dart';

part 'youtube_chat_message.freezed.dart';
part 'youtube_chat_message.g.dart';

/// Typed view on `snippet.type` of a liveChatMessage REST resource.
/// Anything new or unrecognized on Google's side (e.g. `giftEvent`)
/// falls back to [unknown] so parsing never breaks forward-compat.
enum YouTubeChatMessageType {
  textMessage,
  superChat,
  superSticker,
  newSponsor,
  memberMilestone,
  membershipGifting,
  giftMembershipReceived,
  poll,
  userBanned,
  tombstone,
  sponsorOnlyModeStarted,
  sponsorOnlyModeEnded,
  chatEnded,
  unknown;

  static YouTubeChatMessageType parse(Object? value) => switch (value) {
    'textMessageEvent' => textMessage,
    'superChatEvent' => superChat,
    'superStickerEvent' => superSticker,
    'newSponsorEvent' => newSponsor,
    'memberMilestoneChatEvent' => memberMilestone,
    'membershipGiftingEvent' => membershipGifting,
    'giftMembershipReceivedEvent' => giftMembershipReceived,
    'pollEvent' => poll,
    'userBannedEvent' => userBanned,
    'tombstone' => tombstone,
    'sponsorOnlyModeStartedEvent' => sponsorOnlyModeStarted,
    'sponsorOnlyModeEndedEvent' => sponsorOnlyModeEnded,
    'chatEndedEvent' => chatEnded,
    _ => unknown,
  };
}

/// A `liveChatMessage` REST resource
/// (https://developers.google.com/youtube/v3/live/docs/liveChatMessages).
@Freezed(fromJson: true, toJson: false)
abstract class YouTubeChatMessage with _$YouTubeChatMessage {
  const YouTubeChatMessage._();

  const factory YouTubeChatMessage({
    required String id,
    required YouTubeChatMessageSnippet snippet,
    YouTubeChatAuthorDetails? authorDetails,

    /// Local lifecycle flag — set by the chat store when a `tombstone`
    /// arrives for this message (dim + marker, same UX as Twitch);
    /// never part of the API JSON.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool isTombstoned,
  }) = _YouTubeChatMessage;

  factory YouTubeChatMessage.fromJson(Map<String, Object?> json) =>
      _$YouTubeChatMessageFromJson(json);

  YouTubeChatMessageType get type => this.snippet.type;
  DateTime get publishedAt => this.snippet.publishedAt;

  /// For `userBanned` events this is the acting moderator's channel id.
  String? get authorChannelId => this.snippet.authorChannelId;
  String? get displayText => this.snippet.displayMessage;
  String? get authorName => this.authorDetails?.displayName;
  String? get authorProfileImageUrl => this.authorDetails?.profileImageUrl;
  bool get isOwner => this.authorDetails?.isChatOwner ?? false;
  bool get isModerator => this.authorDetails?.isChatModerator ?? false;
  bool get isSponsor => this.authorDetails?.isChatSponsor ?? false;
  bool get isVerified => this.authorDetails?.isVerified ?? false;
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeChatMessageSnippet with _$YouTubeChatMessageSnippet {
  const factory YouTubeChatMessageSnippet({
    @JsonKey(fromJson: YouTubeChatMessageType.parse)
    required YouTubeChatMessageType type,
    String? liveChatId,
    String? authorChannelId,
    required DateTime publishedAt,
    @Default(false) bool hasDisplayContent,
    String? displayMessage,
    YouTubeTextMessageDetails? textMessageDetails,
    YouTubeSuperChatDetails? superChatDetails,
    YouTubeSuperStickerDetails? superStickerDetails,
    YouTubeNewSponsorDetails? newSponsorDetails,
    YouTubeMemberMilestoneDetails? memberMilestoneChatDetails,
    YouTubeMembershipGiftingDetails? membershipGiftingDetails,
    YouTubeGiftMembershipReceivedDetails? giftMembershipReceivedDetails,
    YouTubePollDetails? pollDetails,
    YouTubeUserBannedDetails? userBannedDetails,
  }) = _YouTubeChatMessageSnippet;

  factory YouTubeChatMessageSnippet.fromJson(Map<String, Object?> json) =>
      _$YouTubeChatMessageSnippetFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeChatAuthorDetails with _$YouTubeChatAuthorDetails {
  const factory YouTubeChatAuthorDetails({
    String? channelId,
    String? channelUrl,
    String? displayName,
    String? profileImageUrl,
    @Default(false) bool isVerified,
    @Default(false) bool isChatOwner,
    @Default(false) bool isChatSponsor,
    @Default(false) bool isChatModerator,
  }) = _YouTubeChatAuthorDetails;

  factory YouTubeChatAuthorDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeChatAuthorDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeTextMessageDetails with _$YouTubeTextMessageDetails {
  const factory YouTubeTextMessageDetails({required String messageText}) =
      _YouTubeTextMessageDetails;

  factory YouTubeTextMessageDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeTextMessageDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeSuperChatDetails with _$YouTubeSuperChatDetails {
  const factory YouTubeSuperChatDetails({
    /// unsigned long — serialized as a string in the JSON
    String? amountMicros,
    String? currency,
    String? amountDisplayString,
    String? userComment,
    @Default(0) int tier,
  }) = _YouTubeSuperChatDetails;

  factory YouTubeSuperChatDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeSuperChatDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeSuperStickerDetails with _$YouTubeSuperStickerDetails {
  const factory YouTubeSuperStickerDetails({
    YouTubeSuperStickerMetadata? superStickerMetadata,

    /// unsigned long — serialized as a string in the JSON
    String? amountMicros,
    String? currency,
    String? amountDisplayString,
    @Default(0) int tier,
  }) = _YouTubeSuperStickerDetails;

  factory YouTubeSuperStickerDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeSuperStickerDetailsFromJson(json);
}

/// No sticker image URL is exposed via the API — [altText] is all we get.
@Freezed(fromJson: true, toJson: false)
abstract class YouTubeSuperStickerMetadata with _$YouTubeSuperStickerMetadata {
  const factory YouTubeSuperStickerMetadata({
    String? stickerId,
    String? altText,
    String? language,
  }) = _YouTubeSuperStickerMetadata;

  factory YouTubeSuperStickerMetadata.fromJson(Map<String, Object?> json) =>
      _$YouTubeSuperStickerMetadataFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeNewSponsorDetails with _$YouTubeNewSponsorDetails {
  const factory YouTubeNewSponsorDetails({
    String? memberLevelName,
    @Default(false) bool isUpgrade,
  }) = _YouTubeNewSponsorDetails;

  factory YouTubeNewSponsorDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeNewSponsorDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeMemberMilestoneDetails
    with _$YouTubeMemberMilestoneDetails {
  const factory YouTubeMemberMilestoneDetails({
    String? userComment,
    @Default(0) int memberMonth,
    String? memberLevelName,
  }) = _YouTubeMemberMilestoneDetails;

  factory YouTubeMemberMilestoneDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeMemberMilestoneDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeMembershipGiftingDetails
    with _$YouTubeMembershipGiftingDetails {
  const factory YouTubeMembershipGiftingDetails({
    @Default(0) int giftMembershipsCount,
    String? giftMembershipsLevelName,
  }) = _YouTubeMembershipGiftingDetails;

  factory YouTubeMembershipGiftingDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeMembershipGiftingDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeGiftMembershipReceivedDetails
    with _$YouTubeGiftMembershipReceivedDetails {
  const factory YouTubeGiftMembershipReceivedDetails({
    String? memberLevelName,
    String? gifterChannelId,
    String? associatedMembershipGiftingMessageId,
  }) = _YouTubeGiftMembershipReceivedDetails;

  factory YouTubeGiftMembershipReceivedDetails.fromJson(
    Map<String, Object?> json,
  ) => _$YouTubeGiftMembershipReceivedDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubePollDetails with _$YouTubePollDetails {
  const factory YouTubePollDetails({YouTubePollMetadata? metadata}) =
      _YouTubePollDetails;

  factory YouTubePollDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubePollDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubePollMetadata with _$YouTubePollMetadata {
  const factory YouTubePollMetadata({
    String? questionText,
    @Default(<YouTubePollOption>[]) List<YouTubePollOption> options,

    /// `unknown` | `active` | `closed` — tallies are owner-only.
    String? status,
  }) = _YouTubePollMetadata;

  factory YouTubePollMetadata.fromJson(Map<String, Object?> json) =>
      _$YouTubePollMetadataFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubePollOption with _$YouTubePollOption {
  const factory YouTubePollOption({
    String? optionText,

    /// Only present when the request was authorized by the channel owner.
    String? tally,
  }) = _YouTubePollOption;

  factory YouTubePollOption.fromJson(Map<String, Object?> json) =>
      _$YouTubePollOptionFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeUserBannedDetails with _$YouTubeUserBannedDetails {
  const factory YouTubeUserBannedDetails({
    YouTubeBannedUserDetails? bannedUserDetails,

    /// `permanent` | `temporary`
    String? banType,

    /// Only present for temporary bans (timeouts).
    int? banDurationSeconds,
  }) = _YouTubeUserBannedDetails;

  factory YouTubeUserBannedDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeUserBannedDetailsFromJson(json);
}

@Freezed(fromJson: true, toJson: false)
abstract class YouTubeBannedUserDetails with _$YouTubeBannedUserDetails {
  const factory YouTubeBannedUserDetails({
    String? channelId,
    String? channelUrl,
    String? displayName,
    String? profileImageUrl,
  }) = _YouTubeBannedUserDetails;

  factory YouTubeBannedUserDetails.fromJson(Map<String, Object?> json) =>
      _$YouTubeBannedUserDetailsFromJson(json);
}
