// This is a generated file - do not edit.
//
// Generated from stream_list.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart'
    as $1;

import 'stream_list.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'stream_list.pbenum.dart';

class LiveChatMessageListRequest extends $pb.GeneratedMessage {
  factory LiveChatMessageListRequest({
    $core.String? liveChatId,
    $core.String? hl,
    $core.int? profileImageSize,
    $core.int? maxResults,
    $core.String? pageToken,
    $core.Iterable<$core.String>? part,
  }) {
    final result = create();
    if (liveChatId != null) result.liveChatId = liveChatId;
    if (hl != null) result.hl = hl;
    if (profileImageSize != null) result.profileImageSize = profileImageSize;
    if (maxResults != null) result.maxResults = maxResults;
    if (pageToken != null) result.pageToken = pageToken;
    if (part != null) result.part.addAll(part);
    return result;
  }

  LiveChatMessageListRequest._();

  factory LiveChatMessageListRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMessageListRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMessageListRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'liveChatId')
    ..aOS(2, _omitFieldNames ? '' : 'hl')
    ..aI(3, _omitFieldNames ? '' : 'profileImageSize',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(98, _omitFieldNames ? '' : 'maxResults',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(99, _omitFieldNames ? '' : 'pageToken')
    ..pPS(100, _omitFieldNames ? '' : 'part')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageListRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageListRequest copyWith(
          void Function(LiveChatMessageListRequest) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatMessageListRequest))
          as LiveChatMessageListRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMessageListRequest create() => LiveChatMessageListRequest._();
  @$core.override
  LiveChatMessageListRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMessageListRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMessageListRequest>(create);
  static LiveChatMessageListRequest? _defaultInstance;

  /// The ID of the live chat for which comments should be returned.
  @$pb.TagNumber(1)
  $core.String get liveChatId => $_getSZ(0);
  @$pb.TagNumber(1)
  set liveChatId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLiveChatId() => $_has(0);
  @$pb.TagNumber(1)
  void clearLiveChatId() => $_clearField(1);

  /// Specifies the localization language in which the system messages
  /// should be returned.
  @$pb.TagNumber(2)
  $core.String get hl => $_getSZ(1);
  @$pb.TagNumber(2)
  set hl($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHl() => $_has(1);
  @$pb.TagNumber(2)
  void clearHl() => $_clearField(2);

  /// Specifies the size of the profile image that should be
  /// returned for each user.
  @$pb.TagNumber(3)
  $core.int get profileImageSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set profileImageSize($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProfileImageSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearProfileImageSize() => $_clearField(3);

  /// The <code><strong>maxResults</strong></code> parameter specifies the
  /// maximum number of items that should be returned in the result set.
  /// Not used in the streaming RPC.
  @$pb.TagNumber(98)
  $core.int get maxResults => $_getIZ(3);
  @$pb.TagNumber(98)
  set maxResults($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(98)
  $core.bool hasMaxResults() => $_has(3);
  @$pb.TagNumber(98)
  void clearMaxResults() => $_clearField(98);

  /// The <code><strong>pageToken</strong></code> parameter identifies a specific
  /// page in the result set that should be returned. In an API response, the
  /// <code>nextPageToken</code> property identify other pages that could be
  /// retrieved.
  @$pb.TagNumber(99)
  $core.String get pageToken => $_getSZ(4);
  @$pb.TagNumber(99)
  set pageToken($core.String value) => $_setString(4, value);
  @$pb.TagNumber(99)
  $core.bool hasPageToken() => $_has(4);
  @$pb.TagNumber(99)
  void clearPageToken() => $_clearField(99);

  /// The <code><strong>part</strong></code> parameter specifies the
  /// <code>liveChatComment</code> resource parts that the API response will
  /// include. Supported values are <code>id</code>, <code>snippet</code>, and
  /// <code>authorDetails</code>.
  @$pb.TagNumber(100)
  $pb.PbList<$core.String> get part => $_getList(5);
}

class LiveChatMessageListResponse extends $pb.GeneratedMessage {
  factory LiveChatMessageListResponse({
    $core.String? offlineAt,
    $core.String? kind,
    $core.String? etag,
    PageInfo? pageInfo,
    $core.Iterable<LiveChatMessage>? items,
    LiveChatMessage? activePollItem,
    $core.String? nextPageToken,
  }) {
    final result = create();
    if (offlineAt != null) result.offlineAt = offlineAt;
    if (kind != null) result.kind = kind;
    if (etag != null) result.etag = etag;
    if (pageInfo != null) result.pageInfo = pageInfo;
    if (items != null) result.items.addAll(items);
    if (activePollItem != null) result.activePollItem = activePollItem;
    if (nextPageToken != null) result.nextPageToken = nextPageToken;
    return result;
  }

  LiveChatMessageListResponse._();

  factory LiveChatMessageListResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMessageListResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMessageListResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'offlineAt')
    ..aOS(200, _omitFieldNames ? '' : 'kind')
    ..aOS(201, _omitFieldNames ? '' : 'etag')
    ..aOM<PageInfo>(1004, _omitFieldNames ? '' : 'pageInfo',
        subBuilder: PageInfo.create)
    ..pPM<LiveChatMessage>(1007, _omitFieldNames ? '' : 'items',
        subBuilder: LiveChatMessage.create)
    ..aOM<LiveChatMessage>(1008, _omitFieldNames ? '' : 'activePollItem',
        subBuilder: LiveChatMessage.create)
    ..aOS(100602, _omitFieldNames ? '' : 'nextPageToken')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageListResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageListResponse copyWith(
          void Function(LiveChatMessageListResponse) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatMessageListResponse))
          as LiveChatMessageListResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMessageListResponse create() =>
      LiveChatMessageListResponse._();
  @$core.override
  LiveChatMessageListResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMessageListResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMessageListResponse>(create);
  static LiveChatMessageListResponse? _defaultInstance;

  /// The date and time when the underlying stream went offline. The value is
  /// specified in <a href="//www.w3.org/TR/NOTE-datetime">ISO 8601</a>
  /// format.
  @$pb.TagNumber(2)
  $core.String get offlineAt => $_getSZ(0);
  @$pb.TagNumber(2)
  set offlineAt($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasOfflineAt() => $_has(0);
  @$pb.TagNumber(2)
  void clearOfflineAt() => $_clearField(2);

  /// Identifies what kind of resource this is. Value: the fixed string
  /// <code>"youtube#liveChatMessageListResponse"</code>.
  @$pb.TagNumber(200)
  $core.String get kind => $_getSZ(1);
  @$pb.TagNumber(200)
  set kind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(200)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(200)
  void clearKind() => $_clearField(200);

  /// Etag of this resource.
  @$pb.TagNumber(201)
  $core.String get etag => $_getSZ(2);
  @$pb.TagNumber(201)
  set etag($core.String value) => $_setString(2, value);
  @$pb.TagNumber(201)
  $core.bool hasEtag() => $_has(2);
  @$pb.TagNumber(201)
  void clearEtag() => $_clearField(201);

  /// General pagination information.
  @$pb.TagNumber(1004)
  PageInfo get pageInfo => $_getN(3);
  @$pb.TagNumber(1004)
  set pageInfo(PageInfo value) => $_setField(1004, value);
  @$pb.TagNumber(1004)
  $core.bool hasPageInfo() => $_has(3);
  @$pb.TagNumber(1004)
  void clearPageInfo() => $_clearField(1004);
  @$pb.TagNumber(1004)
  PageInfo ensurePageInfo() => $_ensure(3);

  @$pb.TagNumber(1007)
  $pb.PbList<LiveChatMessage> get items => $_getList(4);

  /// Set when there is an active poll.
  @$pb.TagNumber(1008)
  LiveChatMessage get activePollItem => $_getN(5);
  @$pb.TagNumber(1008)
  set activePollItem(LiveChatMessage value) => $_setField(1008, value);
  @$pb.TagNumber(1008)
  $core.bool hasActivePollItem() => $_has(5);
  @$pb.TagNumber(1008)
  void clearActivePollItem() => $_clearField(1008);
  @$pb.TagNumber(1008)
  LiveChatMessage ensureActivePollItem() => $_ensure(5);

  @$pb.TagNumber(100602)
  $core.String get nextPageToken => $_getSZ(6);
  @$pb.TagNumber(100602)
  set nextPageToken($core.String value) => $_setString(6, value);
  @$pb.TagNumber(100602)
  $core.bool hasNextPageToken() => $_has(6);
  @$pb.TagNumber(100602)
  void clearNextPageToken() => $_clearField(100602);
}

class LiveChatMessage extends $pb.GeneratedMessage {
  factory LiveChatMessage({
    LiveChatMessageSnippet? snippet,
    LiveChatMessageAuthorDetails? authorDetails,
    $core.String? id,
    $core.String? kind,
    $core.String? etag,
  }) {
    final result = create();
    if (snippet != null) result.snippet = snippet;
    if (authorDetails != null) result.authorDetails = authorDetails;
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (etag != null) result.etag = etag;
    return result;
  }

  LiveChatMessage._();

  factory LiveChatMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOM<LiveChatMessageSnippet>(2, _omitFieldNames ? '' : 'snippet',
        subBuilder: LiveChatMessageSnippet.create)
    ..aOM<LiveChatMessageAuthorDetails>(
        3, _omitFieldNames ? '' : 'authorDetails',
        subBuilder: LiveChatMessageAuthorDetails.create)
    ..aOS(101, _omitFieldNames ? '' : 'id')
    ..aOS(200, _omitFieldNames ? '' : 'kind')
    ..aOS(201, _omitFieldNames ? '' : 'etag')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessage copyWith(void Function(LiveChatMessage) updates) =>
      super.copyWith((message) => updates(message as LiveChatMessage))
          as LiveChatMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMessage create() => LiveChatMessage._();
  @$core.override
  LiveChatMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMessage>(create);
  static LiveChatMessage? _defaultInstance;

  /// The <code>snippet</code> object contains basic details about the message.
  @$pb.TagNumber(2)
  LiveChatMessageSnippet get snippet => $_getN(0);
  @$pb.TagNumber(2)
  set snippet(LiveChatMessageSnippet value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSnippet() => $_has(0);
  @$pb.TagNumber(2)
  void clearSnippet() => $_clearField(2);
  @$pb.TagNumber(2)
  LiveChatMessageSnippet ensureSnippet() => $_ensure(0);

  /// The <code>authorDetails</code> object contains basic details about the
  /// user that posted this message.
  @$pb.TagNumber(3)
  LiveChatMessageAuthorDetails get authorDetails => $_getN(1);
  @$pb.TagNumber(3)
  set authorDetails(LiveChatMessageAuthorDetails value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthorDetails() => $_has(1);
  @$pb.TagNumber(3)
  void clearAuthorDetails() => $_clearField(3);
  @$pb.TagNumber(3)
  LiveChatMessageAuthorDetails ensureAuthorDetails() => $_ensure(1);

  /// The ID that YouTube assigns to uniquely identify the message.
  /// Note: For giftEvents, the same ID may be reused to update the combo count.
  @$pb.TagNumber(101)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(101)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(101)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(101)
  void clearId() => $_clearField(101);

  /// Identifies what kind of resource this is. Value: the fixed string
  /// <code>"youtube#liveChatMessage"</code>.
  @$pb.TagNumber(200)
  $core.String get kind => $_getSZ(3);
  @$pb.TagNumber(200)
  set kind($core.String value) => $_setString(3, value);
  @$pb.TagNumber(200)
  $core.bool hasKind() => $_has(3);
  @$pb.TagNumber(200)
  void clearKind() => $_clearField(200);

  /// Etag of this resource.
  @$pb.TagNumber(201)
  $core.String get etag => $_getSZ(4);
  @$pb.TagNumber(201)
  set etag($core.String value) => $_setString(4, value);
  @$pb.TagNumber(201)
  $core.bool hasEtag() => $_has(4);
  @$pb.TagNumber(201)
  void clearEtag() => $_clearField(201);
}

class LiveChatMessageAuthorDetails extends $pb.GeneratedMessage {
  factory LiveChatMessageAuthorDetails({
    $core.bool? isVerified,
    $core.bool? isChatOwner,
    $core.bool? isChatSponsor,
    $core.bool? isChatModerator,
    $core.String? channelUrl,
    $core.String? displayName,
    $core.String? profileImageUrl,
    $core.String? channelId,
  }) {
    final result = create();
    if (isVerified != null) result.isVerified = isVerified;
    if (isChatOwner != null) result.isChatOwner = isChatOwner;
    if (isChatSponsor != null) result.isChatSponsor = isChatSponsor;
    if (isChatModerator != null) result.isChatModerator = isChatModerator;
    if (channelUrl != null) result.channelUrl = channelUrl;
    if (displayName != null) result.displayName = displayName;
    if (profileImageUrl != null) result.profileImageUrl = profileImageUrl;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  LiveChatMessageAuthorDetails._();

  factory LiveChatMessageAuthorDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMessageAuthorDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMessageAuthorDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOB(4, _omitFieldNames ? '' : 'isVerified')
    ..aOB(5, _omitFieldNames ? '' : 'isChatOwner')
    ..aOB(6, _omitFieldNames ? '' : 'isChatSponsor')
    ..aOB(7, _omitFieldNames ? '' : 'isChatModerator')
    ..aOS(102, _omitFieldNames ? '' : 'channelUrl')
    ..aOS(103, _omitFieldNames ? '' : 'displayName')
    ..aOS(104, _omitFieldNames ? '' : 'profileImageUrl')
    ..aOS(10101, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageAuthorDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageAuthorDetails copyWith(
          void Function(LiveChatMessageAuthorDetails) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatMessageAuthorDetails))
          as LiveChatMessageAuthorDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMessageAuthorDetails create() =>
      LiveChatMessageAuthorDetails._();
  @$core.override
  LiveChatMessageAuthorDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMessageAuthorDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMessageAuthorDetails>(create);
  static LiveChatMessageAuthorDetails? _defaultInstance;

  /// Whether the author's identity has been verified by YouTube.
  @$pb.TagNumber(4)
  $core.bool get isVerified => $_getBF(0);
  @$pb.TagNumber(4)
  set isVerified($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(4)
  $core.bool hasIsVerified() => $_has(0);
  @$pb.TagNumber(4)
  void clearIsVerified() => $_clearField(4);

  /// Whether the author is the owner of the live chat.
  @$pb.TagNumber(5)
  $core.bool get isChatOwner => $_getBF(1);
  @$pb.TagNumber(5)
  set isChatOwner($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(5)
  $core.bool hasIsChatOwner() => $_has(1);
  @$pb.TagNumber(5)
  void clearIsChatOwner() => $_clearField(5);

  /// Whether the author is a sponsor of the live chat.
  @$pb.TagNumber(6)
  $core.bool get isChatSponsor => $_getBF(2);
  @$pb.TagNumber(6)
  set isChatSponsor($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(6)
  $core.bool hasIsChatSponsor() => $_has(2);
  @$pb.TagNumber(6)
  void clearIsChatSponsor() => $_clearField(6);

  /// Whether the author is a moderator of the live chat.
  @$pb.TagNumber(7)
  $core.bool get isChatModerator => $_getBF(3);
  @$pb.TagNumber(7)
  set isChatModerator($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(7)
  $core.bool hasIsChatModerator() => $_has(3);
  @$pb.TagNumber(7)
  void clearIsChatModerator() => $_clearField(7);

  /// The channel's URL.
  @$pb.TagNumber(102)
  $core.String get channelUrl => $_getSZ(4);
  @$pb.TagNumber(102)
  set channelUrl($core.String value) => $_setString(4, value);
  @$pb.TagNumber(102)
  $core.bool hasChannelUrl() => $_has(4);
  @$pb.TagNumber(102)
  void clearChannelUrl() => $_clearField(102);

  /// The channel's display name.
  @$pb.TagNumber(103)
  $core.String get displayName => $_getSZ(5);
  @$pb.TagNumber(103)
  set displayName($core.String value) => $_setString(5, value);
  @$pb.TagNumber(103)
  $core.bool hasDisplayName() => $_has(5);
  @$pb.TagNumber(103)
  void clearDisplayName() => $_clearField(103);

  /// The channels's avatar URL.
  @$pb.TagNumber(104)
  $core.String get profileImageUrl => $_getSZ(6);
  @$pb.TagNumber(104)
  set profileImageUrl($core.String value) => $_setString(6, value);
  @$pb.TagNumber(104)
  $core.bool hasProfileImageUrl() => $_has(6);
  @$pb.TagNumber(104)
  void clearProfileImageUrl() => $_clearField(104);

  /// The YouTube channel ID.
  @$pb.TagNumber(10101)
  $core.String get channelId => $_getSZ(7);
  @$pb.TagNumber(10101)
  set channelId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(10101)
  $core.bool hasChannelId() => $_has(7);
  @$pb.TagNumber(10101)
  void clearChannelId() => $_clearField(10101);
}

class LiveChatMessageSnippet_TypeWrapper extends $pb.GeneratedMessage {
  factory LiveChatMessageSnippet_TypeWrapper() => create();

  LiveChatMessageSnippet_TypeWrapper._();

  factory LiveChatMessageSnippet_TypeWrapper.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMessageSnippet_TypeWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMessageSnippet.TypeWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageSnippet_TypeWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageSnippet_TypeWrapper copyWith(
          void Function(LiveChatMessageSnippet_TypeWrapper) updates) =>
      super.copyWith((message) =>
              updates(message as LiveChatMessageSnippet_TypeWrapper))
          as LiveChatMessageSnippet_TypeWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMessageSnippet_TypeWrapper create() =>
      LiveChatMessageSnippet_TypeWrapper._();
  @$core.override
  LiveChatMessageSnippet_TypeWrapper createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMessageSnippet_TypeWrapper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMessageSnippet_TypeWrapper>(
          create);
  static LiveChatMessageSnippet_TypeWrapper? _defaultInstance;
}

enum LiveChatMessageSnippet_DisplayedContent {
  textMessageDetails,
  userBannedDetails,
  superChatDetails,
  superStickerDetails,
  newSponsorDetails,
  memberMilestoneChatDetails,
  membershipGiftingDetails,
  giftMembershipReceivedDetails,
  pollDetails,
  giftDetails,
  notSet
}

class LiveChatMessageSnippet extends $pb.GeneratedMessage {
  factory LiveChatMessageSnippet({
    LiveChatMessageSnippet_TypeWrapper_Type? type,
    $core.String? publishedAt,
    $core.String? displayMessage,
    $core.bool? hasDisplayContent,
    LiveChatTextMessageDetails? textMessageDetails,
    LiveChatUserBannedMessageDetails? userBannedDetails,
    LiveChatSuperChatDetails? superChatDetails,
    LiveChatSuperStickerDetails? superStickerDetails,
    LiveChatNewSponsorDetails? newSponsorDetails,
    LiveChatMemberMilestoneChatDetails? memberMilestoneChatDetails,
    LiveChatMembershipGiftingDetails? membershipGiftingDetails,
    LiveChatGiftMembershipReceivedDetails? giftMembershipReceivedDetails,
    LiveChatPollDetails? pollDetails,
    LiveChatGiftDetails? giftDetails,
    $core.String? liveChatId,
    $core.String? authorChannelId,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (publishedAt != null) result.publishedAt = publishedAt;
    if (displayMessage != null) result.displayMessage = displayMessage;
    if (hasDisplayContent != null) result.hasDisplayContent = hasDisplayContent;
    if (textMessageDetails != null)
      result.textMessageDetails = textMessageDetails;
    if (userBannedDetails != null) result.userBannedDetails = userBannedDetails;
    if (superChatDetails != null) result.superChatDetails = superChatDetails;
    if (superStickerDetails != null)
      result.superStickerDetails = superStickerDetails;
    if (newSponsorDetails != null) result.newSponsorDetails = newSponsorDetails;
    if (memberMilestoneChatDetails != null)
      result.memberMilestoneChatDetails = memberMilestoneChatDetails;
    if (membershipGiftingDetails != null)
      result.membershipGiftingDetails = membershipGiftingDetails;
    if (giftMembershipReceivedDetails != null)
      result.giftMembershipReceivedDetails = giftMembershipReceivedDetails;
    if (pollDetails != null) result.pollDetails = pollDetails;
    if (giftDetails != null) result.giftDetails = giftDetails;
    if (liveChatId != null) result.liveChatId = liveChatId;
    if (authorChannelId != null) result.authorChannelId = authorChannelId;
    return result;
  }

  LiveChatMessageSnippet._();

  factory LiveChatMessageSnippet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMessageSnippet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LiveChatMessageSnippet_DisplayedContent>
      _LiveChatMessageSnippet_DisplayedContentByTag = {
    19: LiveChatMessageSnippet_DisplayedContent.textMessageDetails,
    22: LiveChatMessageSnippet_DisplayedContent.userBannedDetails,
    27: LiveChatMessageSnippet_DisplayedContent.superChatDetails,
    28: LiveChatMessageSnippet_DisplayedContent.superStickerDetails,
    29: LiveChatMessageSnippet_DisplayedContent.newSponsorDetails,
    30: LiveChatMessageSnippet_DisplayedContent.memberMilestoneChatDetails,
    31: LiveChatMessageSnippet_DisplayedContent.membershipGiftingDetails,
    32: LiveChatMessageSnippet_DisplayedContent.giftMembershipReceivedDetails,
    33: LiveChatMessageSnippet_DisplayedContent.pollDetails,
    34: LiveChatMessageSnippet_DisplayedContent.giftDetails,
    0: LiveChatMessageSnippet_DisplayedContent.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMessageSnippet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..oo(0, [19, 22, 27, 28, 29, 30, 31, 32, 33, 34])
    ..aE<LiveChatMessageSnippet_TypeWrapper_Type>(
        1, _omitFieldNames ? '' : 'type',
        enumValues: LiveChatMessageSnippet_TypeWrapper_Type.values)
    ..aOS(4, _omitFieldNames ? '' : 'publishedAt')
    ..aOS(16, _omitFieldNames ? '' : 'displayMessage')
    ..aOB(17, _omitFieldNames ? '' : 'hasDisplayContent')
    ..aOM<LiveChatTextMessageDetails>(
        19, _omitFieldNames ? '' : 'textMessageDetails',
        subBuilder: LiveChatTextMessageDetails.create)
    ..aOM<LiveChatUserBannedMessageDetails>(
        22, _omitFieldNames ? '' : 'userBannedDetails',
        subBuilder: LiveChatUserBannedMessageDetails.create)
    ..aOM<LiveChatSuperChatDetails>(
        27, _omitFieldNames ? '' : 'superChatDetails',
        subBuilder: LiveChatSuperChatDetails.create)
    ..aOM<LiveChatSuperStickerDetails>(
        28, _omitFieldNames ? '' : 'superStickerDetails',
        subBuilder: LiveChatSuperStickerDetails.create)
    ..aOM<LiveChatNewSponsorDetails>(
        29, _omitFieldNames ? '' : 'newSponsorDetails',
        subBuilder: LiveChatNewSponsorDetails.create)
    ..aOM<LiveChatMemberMilestoneChatDetails>(
        30, _omitFieldNames ? '' : 'memberMilestoneChatDetails',
        subBuilder: LiveChatMemberMilestoneChatDetails.create)
    ..aOM<LiveChatMembershipGiftingDetails>(
        31, _omitFieldNames ? '' : 'membershipGiftingDetails',
        subBuilder: LiveChatMembershipGiftingDetails.create)
    ..aOM<LiveChatGiftMembershipReceivedDetails>(
        32, _omitFieldNames ? '' : 'giftMembershipReceivedDetails',
        subBuilder: LiveChatGiftMembershipReceivedDetails.create)
    ..aOM<LiveChatPollDetails>(33, _omitFieldNames ? '' : 'pollDetails',
        subBuilder: LiveChatPollDetails.create)
    ..aOM<LiveChatGiftDetails>(34, _omitFieldNames ? '' : 'giftDetails',
        subBuilder: LiveChatGiftDetails.create)
    ..aOS(201, _omitFieldNames ? '' : 'liveChatId')
    ..aOS(301, _omitFieldNames ? '' : 'authorChannelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageSnippet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMessageSnippet copyWith(
          void Function(LiveChatMessageSnippet) updates) =>
      super.copyWith((message) => updates(message as LiveChatMessageSnippet))
          as LiveChatMessageSnippet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMessageSnippet create() => LiveChatMessageSnippet._();
  @$core.override
  LiveChatMessageSnippet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMessageSnippet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMessageSnippet>(create);
  static LiveChatMessageSnippet? _defaultInstance;

  @$pb.TagNumber(19)
  @$pb.TagNumber(22)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  LiveChatMessageSnippet_DisplayedContent whichDisplayedContent() =>
      _LiveChatMessageSnippet_DisplayedContentByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(19)
  @$pb.TagNumber(22)
  @$pb.TagNumber(27)
  @$pb.TagNumber(28)
  @$pb.TagNumber(29)
  @$pb.TagNumber(30)
  @$pb.TagNumber(31)
  @$pb.TagNumber(32)
  @$pb.TagNumber(33)
  @$pb.TagNumber(34)
  void clearDisplayedContent() => $_clearField($_whichOneof(0));

  /// The type of message, this will always be present, it determines the
  /// contents of the message as well as which fields will be present.
  @$pb.TagNumber(1)
  LiveChatMessageSnippet_TypeWrapper_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(LiveChatMessageSnippet_TypeWrapper_Type value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  /// The date and time when the message was orignally published. The value is
  /// specified in <a href="//www.w3.org/TR/NOTE-datetime">ISO 8601</a>
  /// format.
  @$pb.TagNumber(4)
  $core.String get publishedAt => $_getSZ(1);
  @$pb.TagNumber(4)
  set publishedAt($core.String value) => $_setString(1, value);
  @$pb.TagNumber(4)
  $core.bool hasPublishedAt() => $_has(1);
  @$pb.TagNumber(4)
  void clearPublishedAt() => $_clearField(4);

  /// Contains a string that can be displayed to the user.
  /// If this field is not present the message is silent, at the moment only
  /// messages of type TOMBSTONE and CHAT_ENDED_EVENT are silent.
  @$pb.TagNumber(16)
  $core.String get displayMessage => $_getSZ(2);
  @$pb.TagNumber(16)
  set displayMessage($core.String value) => $_setString(2, value);
  @$pb.TagNumber(16)
  $core.bool hasDisplayMessage() => $_has(2);
  @$pb.TagNumber(16)
  void clearDisplayMessage() => $_clearField(16);

  /// Whether the message has display content that should be displayed to users.
  @$pb.TagNumber(17)
  $core.bool get hasDisplayContent => $_getBF(3);
  @$pb.TagNumber(17)
  set hasDisplayContent($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(17)
  $core.bool hasHasDisplayContent() => $_has(3);
  @$pb.TagNumber(17)
  void clearHasDisplayContent() => $_clearField(17);

  /// Details about the text message, this is only set if the type is
  /// 'textMessageEvent'.
  @$pb.TagNumber(19)
  LiveChatTextMessageDetails get textMessageDetails => $_getN(4);
  @$pb.TagNumber(19)
  set textMessageDetails(LiveChatTextMessageDetails value) =>
      $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasTextMessageDetails() => $_has(4);
  @$pb.TagNumber(19)
  void clearTextMessageDetails() => $_clearField(19);
  @$pb.TagNumber(19)
  LiveChatTextMessageDetails ensureTextMessageDetails() => $_ensure(4);

  @$pb.TagNumber(22)
  LiveChatUserBannedMessageDetails get userBannedDetails => $_getN(5);
  @$pb.TagNumber(22)
  set userBannedDetails(LiveChatUserBannedMessageDetails value) =>
      $_setField(22, value);
  @$pb.TagNumber(22)
  $core.bool hasUserBannedDetails() => $_has(5);
  @$pb.TagNumber(22)
  void clearUserBannedDetails() => $_clearField(22);
  @$pb.TagNumber(22)
  LiveChatUserBannedMessageDetails ensureUserBannedDetails() => $_ensure(5);

  /// Details about the Super Chat event, this is only set if the type is
  /// 'superChatEvent'.
  @$pb.TagNumber(27)
  LiveChatSuperChatDetails get superChatDetails => $_getN(6);
  @$pb.TagNumber(27)
  set superChatDetails(LiveChatSuperChatDetails value) => $_setField(27, value);
  @$pb.TagNumber(27)
  $core.bool hasSuperChatDetails() => $_has(6);
  @$pb.TagNumber(27)
  void clearSuperChatDetails() => $_clearField(27);
  @$pb.TagNumber(27)
  LiveChatSuperChatDetails ensureSuperChatDetails() => $_ensure(6);

  /// Details about the Super Sticker event, this is only set if the type is
  /// 'superStickerEvent'.
  @$pb.TagNumber(28)
  LiveChatSuperStickerDetails get superStickerDetails => $_getN(7);
  @$pb.TagNumber(28)
  set superStickerDetails(LiveChatSuperStickerDetails value) =>
      $_setField(28, value);
  @$pb.TagNumber(28)
  $core.bool hasSuperStickerDetails() => $_has(7);
  @$pb.TagNumber(28)
  void clearSuperStickerDetails() => $_clearField(28);
  @$pb.TagNumber(28)
  LiveChatSuperStickerDetails ensureSuperStickerDetails() => $_ensure(7);

  /// Details about the New Member Announcement event, this is only set if
  /// the type is 'newSponsorEvent'. Note that "member" is the new term for
  /// "sponsor".
  @$pb.TagNumber(29)
  LiveChatNewSponsorDetails get newSponsorDetails => $_getN(8);
  @$pb.TagNumber(29)
  set newSponsorDetails(LiveChatNewSponsorDetails value) =>
      $_setField(29, value);
  @$pb.TagNumber(29)
  $core.bool hasNewSponsorDetails() => $_has(8);
  @$pb.TagNumber(29)
  void clearNewSponsorDetails() => $_clearField(29);
  @$pb.TagNumber(29)
  LiveChatNewSponsorDetails ensureNewSponsorDetails() => $_ensure(8);

  /// Details about the Member Milestone Chat event, this is only set if
  /// the type is 'memberMilestoneChatEvent'.
  @$pb.TagNumber(30)
  LiveChatMemberMilestoneChatDetails get memberMilestoneChatDetails =>
      $_getN(9);
  @$pb.TagNumber(30)
  set memberMilestoneChatDetails(LiveChatMemberMilestoneChatDetails value) =>
      $_setField(30, value);
  @$pb.TagNumber(30)
  $core.bool hasMemberMilestoneChatDetails() => $_has(9);
  @$pb.TagNumber(30)
  void clearMemberMilestoneChatDetails() => $_clearField(30);
  @$pb.TagNumber(30)
  LiveChatMemberMilestoneChatDetails ensureMemberMilestoneChatDetails() =>
      $_ensure(9);

  /// Details about the Membership Gifting event, this is only set if the type
  /// is 'membershipGiftingEvent'.
  @$pb.TagNumber(31)
  LiveChatMembershipGiftingDetails get membershipGiftingDetails => $_getN(10);
  @$pb.TagNumber(31)
  set membershipGiftingDetails(LiveChatMembershipGiftingDetails value) =>
      $_setField(31, value);
  @$pb.TagNumber(31)
  $core.bool hasMembershipGiftingDetails() => $_has(10);
  @$pb.TagNumber(31)
  void clearMembershipGiftingDetails() => $_clearField(31);
  @$pb.TagNumber(31)
  LiveChatMembershipGiftingDetails ensureMembershipGiftingDetails() =>
      $_ensure(10);

  /// Details about the Gift Membership Received event, this is only set if the
  /// type is 'giftMembershipReceivedEvent'.
  @$pb.TagNumber(32)
  LiveChatGiftMembershipReceivedDetails get giftMembershipReceivedDetails =>
      $_getN(11);
  @$pb.TagNumber(32)
  set giftMembershipReceivedDetails(
          LiveChatGiftMembershipReceivedDetails value) =>
      $_setField(32, value);
  @$pb.TagNumber(32)
  $core.bool hasGiftMembershipReceivedDetails() => $_has(11);
  @$pb.TagNumber(32)
  void clearGiftMembershipReceivedDetails() => $_clearField(32);
  @$pb.TagNumber(32)
  LiveChatGiftMembershipReceivedDetails ensureGiftMembershipReceivedDetails() =>
      $_ensure(11);

  /// Details about the poll event, this is only set if the type is
  /// 'pollEvent'.
  @$pb.TagNumber(33)
  LiveChatPollDetails get pollDetails => $_getN(12);
  @$pb.TagNumber(33)
  set pollDetails(LiveChatPollDetails value) => $_setField(33, value);
  @$pb.TagNumber(33)
  $core.bool hasPollDetails() => $_has(12);
  @$pb.TagNumber(33)
  void clearPollDetails() => $_clearField(33);
  @$pb.TagNumber(33)
  LiveChatPollDetails ensurePollDetails() => $_ensure(12);

  /// Details about the gift event, this is only set if the type is
  /// 'giftEvent'.
  @$pb.TagNumber(34)
  LiveChatGiftDetails get giftDetails => $_getN(13);
  @$pb.TagNumber(34)
  set giftDetails(LiveChatGiftDetails value) => $_setField(34, value);
  @$pb.TagNumber(34)
  $core.bool hasGiftDetails() => $_has(13);
  @$pb.TagNumber(34)
  void clearGiftDetails() => $_clearField(34);
  @$pb.TagNumber(34)
  LiveChatGiftDetails ensureGiftDetails() => $_ensure(13);

  @$pb.TagNumber(201)
  $core.String get liveChatId => $_getSZ(14);
  @$pb.TagNumber(201)
  set liveChatId($core.String value) => $_setString(14, value);
  @$pb.TagNumber(201)
  $core.bool hasLiveChatId() => $_has(14);
  @$pb.TagNumber(201)
  void clearLiveChatId() => $_clearField(201);

  /// The ID of the user that authored this message, this field is not always
  /// filled.
  /// textMessageEvent - the user that wrote the message
  /// fanFundingEvent - the user that funded the broadcast
  /// newSponsorEvent - the user that just became a sponsor
  /// memberMilestoneChatEvent - the member that sent the message
  /// membershipGiftingEvent - the user that made the purchase
  /// giftMembershipReceivedEvent - the user that received the gift membership
  /// userBannedEvent - the moderator that took the action
  /// superChatEvent - the user that made the purchase
  /// superStickerEvent - the user that made the purchase
  /// pollEvent - the user that created the poll
  /// giftEvent - the user that made the purchase
  @$pb.TagNumber(301)
  $core.String get authorChannelId => $_getSZ(15);
  @$pb.TagNumber(301)
  set authorChannelId($core.String value) => $_setString(15, value);
  @$pb.TagNumber(301)
  $core.bool hasAuthorChannelId() => $_has(15);
  @$pb.TagNumber(301)
  void clearAuthorChannelId() => $_clearField(301);
}

class LiveChatTextMessageDetails extends $pb.GeneratedMessage {
  factory LiveChatTextMessageDetails({
    $core.String? messageText,
  }) {
    final result = create();
    if (messageText != null) result.messageText = messageText;
    return result;
  }

  LiveChatTextMessageDetails._();

  factory LiveChatTextMessageDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatTextMessageDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatTextMessageDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageText')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatTextMessageDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatTextMessageDetails copyWith(
          void Function(LiveChatTextMessageDetails) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatTextMessageDetails))
          as LiveChatTextMessageDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatTextMessageDetails create() => LiveChatTextMessageDetails._();
  @$core.override
  LiveChatTextMessageDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatTextMessageDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatTextMessageDetails>(create);
  static LiveChatTextMessageDetails? _defaultInstance;

  /// The user's message.
  @$pb.TagNumber(1)
  $core.String get messageText => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageText($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageText() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageText() => $_clearField(1);
}

class LiveChatUserBannedMessageDetails_BanTypeWrapper
    extends $pb.GeneratedMessage {
  factory LiveChatUserBannedMessageDetails_BanTypeWrapper() => create();

  LiveChatUserBannedMessageDetails_BanTypeWrapper._();

  factory LiveChatUserBannedMessageDetails_BanTypeWrapper.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatUserBannedMessageDetails_BanTypeWrapper.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'LiveChatUserBannedMessageDetails.BanTypeWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatUserBannedMessageDetails_BanTypeWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatUserBannedMessageDetails_BanTypeWrapper copyWith(
          void Function(LiveChatUserBannedMessageDetails_BanTypeWrapper)
              updates) =>
      super.copyWith((message) => updates(
              message as LiveChatUserBannedMessageDetails_BanTypeWrapper))
          as LiveChatUserBannedMessageDetails_BanTypeWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatUserBannedMessageDetails_BanTypeWrapper create() =>
      LiveChatUserBannedMessageDetails_BanTypeWrapper._();
  @$core.override
  LiveChatUserBannedMessageDetails_BanTypeWrapper createEmptyInstance() =>
      create();
  @$core.pragma('dart2js:noInline')
  static LiveChatUserBannedMessageDetails_BanTypeWrapper getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          LiveChatUserBannedMessageDetails_BanTypeWrapper>(create);
  static LiveChatUserBannedMessageDetails_BanTypeWrapper? _defaultInstance;
}

class LiveChatUserBannedMessageDetails extends $pb.GeneratedMessage {
  factory LiveChatUserBannedMessageDetails({
    ChannelProfileDetails? bannedUserDetails,
    LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType? banType,
    $fixnum.Int64? banDurationSeconds,
  }) {
    final result = create();
    if (bannedUserDetails != null) result.bannedUserDetails = bannedUserDetails;
    if (banType != null) result.banType = banType;
    if (banDurationSeconds != null)
      result.banDurationSeconds = banDurationSeconds;
    return result;
  }

  LiveChatUserBannedMessageDetails._();

  factory LiveChatUserBannedMessageDetails.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatUserBannedMessageDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatUserBannedMessageDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOM<ChannelProfileDetails>(1, _omitFieldNames ? '' : 'bannedUserDetails',
        subBuilder: ChannelProfileDetails.create)
    ..aE<LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType>(
        2, _omitFieldNames ? '' : 'banType',
        enumValues:
            LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType.values)
    ..a<$fixnum.Int64>(
        4, _omitFieldNames ? '' : 'banDurationSeconds', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatUserBannedMessageDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatUserBannedMessageDetails copyWith(
          void Function(LiveChatUserBannedMessageDetails) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatUserBannedMessageDetails))
          as LiveChatUserBannedMessageDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatUserBannedMessageDetails create() =>
      LiveChatUserBannedMessageDetails._();
  @$core.override
  LiveChatUserBannedMessageDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatUserBannedMessageDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatUserBannedMessageDetails>(
          create);
  static LiveChatUserBannedMessageDetails? _defaultInstance;

  /// The details of the user that was banned.
  @$pb.TagNumber(1)
  ChannelProfileDetails get bannedUserDetails => $_getN(0);
  @$pb.TagNumber(1)
  set bannedUserDetails(ChannelProfileDetails value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasBannedUserDetails() => $_has(0);
  @$pb.TagNumber(1)
  void clearBannedUserDetails() => $_clearField(1);
  @$pb.TagNumber(1)
  ChannelProfileDetails ensureBannedUserDetails() => $_ensure(0);

  /// The type of ban.
  @$pb.TagNumber(2)
  LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType get banType =>
      $_getN(1);
  @$pb.TagNumber(2)
  set banType(LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasBanType() => $_has(1);
  @$pb.TagNumber(2)
  void clearBanType() => $_clearField(2);

  /// The duration of the ban. This property is only present if the
  /// <code>banType</code> is <code>temporary</code>.
  @$pb.TagNumber(4)
  $fixnum.Int64 get banDurationSeconds => $_getI64(2);
  @$pb.TagNumber(4)
  set banDurationSeconds($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(4)
  $core.bool hasBanDurationSeconds() => $_has(2);
  @$pb.TagNumber(4)
  void clearBanDurationSeconds() => $_clearField(4);
}

class LiveChatSuperChatDetails extends $pb.GeneratedMessage {
  factory LiveChatSuperChatDetails({
    $fixnum.Int64? amountMicros,
    $core.String? currency,
    $core.String? amountDisplayString,
    $core.String? userComment,
    $core.int? tier,
  }) {
    final result = create();
    if (amountMicros != null) result.amountMicros = amountMicros;
    if (currency != null) result.currency = currency;
    if (amountDisplayString != null)
      result.amountDisplayString = amountDisplayString;
    if (userComment != null) result.userComment = userComment;
    if (tier != null) result.tier = tier;
    return result;
  }

  LiveChatSuperChatDetails._();

  factory LiveChatSuperChatDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatSuperChatDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatSuperChatDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'amountMicros', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..aOS(3, _omitFieldNames ? '' : 'amountDisplayString')
    ..aOS(4, _omitFieldNames ? '' : 'userComment')
    ..aI(5, _omitFieldNames ? '' : 'tier', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatSuperChatDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatSuperChatDetails copyWith(
          void Function(LiveChatSuperChatDetails) updates) =>
      super.copyWith((message) => updates(message as LiveChatSuperChatDetails))
          as LiveChatSuperChatDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatSuperChatDetails create() => LiveChatSuperChatDetails._();
  @$core.override
  LiveChatSuperChatDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatSuperChatDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatSuperChatDetails>(create);
  static LiveChatSuperChatDetails? _defaultInstance;

  /// The amount purchased by the user, in micros (1,750,000 micros = 1.75).
  @$pb.TagNumber(1)
  $fixnum.Int64 get amountMicros => $_getI64(0);
  @$pb.TagNumber(1)
  set amountMicros($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAmountMicros() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountMicros() => $_clearField(1);

  /// The currency in which the purchase was made.
  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);

  /// A rendered string that displays the fund amount and currency to the user.
  @$pb.TagNumber(3)
  $core.String get amountDisplayString => $_getSZ(2);
  @$pb.TagNumber(3)
  set amountDisplayString($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountDisplayString() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountDisplayString() => $_clearField(3);

  /// The comment added by the user to this Super Chat event.
  @$pb.TagNumber(4)
  $core.String get userComment => $_getSZ(3);
  @$pb.TagNumber(4)
  set userComment($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserComment() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserComment() => $_clearField(4);

  /// The tier in which the amount belongs. Lower amounts belong to lower
  /// tiers. The lowest tier is <code>1</code>.
  @$pb.TagNumber(5)
  $core.int get tier => $_getIZ(4);
  @$pb.TagNumber(5)
  set tier($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTier() => $_has(4);
  @$pb.TagNumber(5)
  void clearTier() => $_clearField(5);
}

class LiveChatSuperStickerDetails extends $pb.GeneratedMessage {
  factory LiveChatSuperStickerDetails({
    $fixnum.Int64? amountMicros,
    $core.String? currency,
    $core.String? amountDisplayString,
    $core.int? tier,
    SuperStickerMetadata? superStickerMetadata,
  }) {
    final result = create();
    if (amountMicros != null) result.amountMicros = amountMicros;
    if (currency != null) result.currency = currency;
    if (amountDisplayString != null)
      result.amountDisplayString = amountDisplayString;
    if (tier != null) result.tier = tier;
    if (superStickerMetadata != null)
      result.superStickerMetadata = superStickerMetadata;
    return result;
  }

  LiveChatSuperStickerDetails._();

  factory LiveChatSuperStickerDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatSuperStickerDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatSuperStickerDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'amountMicros', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..aOS(3, _omitFieldNames ? '' : 'amountDisplayString')
    ..aI(4, _omitFieldNames ? '' : 'tier', fieldType: $pb.PbFieldType.OU3)
    ..aOM<SuperStickerMetadata>(
        5, _omitFieldNames ? '' : 'superStickerMetadata',
        subBuilder: SuperStickerMetadata.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatSuperStickerDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatSuperStickerDetails copyWith(
          void Function(LiveChatSuperStickerDetails) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatSuperStickerDetails))
          as LiveChatSuperStickerDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatSuperStickerDetails create() =>
      LiveChatSuperStickerDetails._();
  @$core.override
  LiveChatSuperStickerDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatSuperStickerDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatSuperStickerDetails>(create);
  static LiveChatSuperStickerDetails? _defaultInstance;

  /// The amount purchased by the user, in micros (1,750,000 micros = 1.75).
  @$pb.TagNumber(1)
  $fixnum.Int64 get amountMicros => $_getI64(0);
  @$pb.TagNumber(1)
  set amountMicros($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAmountMicros() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountMicros() => $_clearField(1);

  /// The currency in which the purchase was made.
  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);

  /// A rendered string that displays the fund amount and currency to the user.
  @$pb.TagNumber(3)
  $core.String get amountDisplayString => $_getSZ(2);
  @$pb.TagNumber(3)
  set amountDisplayString($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountDisplayString() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountDisplayString() => $_clearField(3);

  /// The tier in which the amount belongs. Lower amounts belong to lower
  /// tiers. The lowest tier is <code>1</code>.
  @$pb.TagNumber(4)
  $core.int get tier => $_getIZ(3);
  @$pb.TagNumber(4)
  set tier($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTier() => $_has(3);
  @$pb.TagNumber(4)
  void clearTier() => $_clearField(4);

  /// Information about the Super Sticker.
  @$pb.TagNumber(5)
  SuperStickerMetadata get superStickerMetadata => $_getN(4);
  @$pb.TagNumber(5)
  set superStickerMetadata(SuperStickerMetadata value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSuperStickerMetadata() => $_has(4);
  @$pb.TagNumber(5)
  void clearSuperStickerMetadata() => $_clearField(5);
  @$pb.TagNumber(5)
  SuperStickerMetadata ensureSuperStickerMetadata() => $_ensure(4);
}

class LiveChatFanFundingEventDetails extends $pb.GeneratedMessage {
  factory LiveChatFanFundingEventDetails({
    $fixnum.Int64? amountMicros,
    $core.String? currency,
    $core.String? amountDisplayString,
    $core.String? userComment,
  }) {
    final result = create();
    if (amountMicros != null) result.amountMicros = amountMicros;
    if (currency != null) result.currency = currency;
    if (amountDisplayString != null)
      result.amountDisplayString = amountDisplayString;
    if (userComment != null) result.userComment = userComment;
    return result;
  }

  LiveChatFanFundingEventDetails._();

  factory LiveChatFanFundingEventDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatFanFundingEventDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatFanFundingEventDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'amountMicros', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'currency')
    ..aOS(3, _omitFieldNames ? '' : 'amountDisplayString')
    ..aOS(4, _omitFieldNames ? '' : 'userComment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatFanFundingEventDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatFanFundingEventDetails copyWith(
          void Function(LiveChatFanFundingEventDetails) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatFanFundingEventDetails))
          as LiveChatFanFundingEventDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatFanFundingEventDetails create() =>
      LiveChatFanFundingEventDetails._();
  @$core.override
  LiveChatFanFundingEventDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatFanFundingEventDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatFanFundingEventDetails>(create);
  static LiveChatFanFundingEventDetails? _defaultInstance;

  /// The amount of the fund.
  @$pb.TagNumber(1)
  $fixnum.Int64 get amountMicros => $_getI64(0);
  @$pb.TagNumber(1)
  set amountMicros($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAmountMicros() => $_has(0);
  @$pb.TagNumber(1)
  void clearAmountMicros() => $_clearField(1);

  /// The currency in which the fund was made.
  @$pb.TagNumber(2)
  $core.String get currency => $_getSZ(1);
  @$pb.TagNumber(2)
  set currency($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrency() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrency() => $_clearField(2);

  /// A rendered string that displays the fund amount and currency to the user.
  @$pb.TagNumber(3)
  $core.String get amountDisplayString => $_getSZ(2);
  @$pb.TagNumber(3)
  set amountDisplayString($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAmountDisplayString() => $_has(2);
  @$pb.TagNumber(3)
  void clearAmountDisplayString() => $_clearField(3);

  /// The comment added by the user to this fan funding event.
  @$pb.TagNumber(4)
  $core.String get userComment => $_getSZ(3);
  @$pb.TagNumber(4)
  set userComment($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserComment() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserComment() => $_clearField(4);
}

class LiveChatNewSponsorDetails extends $pb.GeneratedMessage {
  factory LiveChatNewSponsorDetails({
    $core.String? memberLevelName,
    $core.bool? isUpgrade,
  }) {
    final result = create();
    if (memberLevelName != null) result.memberLevelName = memberLevelName;
    if (isUpgrade != null) result.isUpgrade = isUpgrade;
    return result;
  }

  LiveChatNewSponsorDetails._();

  factory LiveChatNewSponsorDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatNewSponsorDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatNewSponsorDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'memberLevelName')
    ..aOB(2, _omitFieldNames ? '' : 'isUpgrade')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatNewSponsorDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatNewSponsorDetails copyWith(
          void Function(LiveChatNewSponsorDetails) updates) =>
      super.copyWith((message) => updates(message as LiveChatNewSponsorDetails))
          as LiveChatNewSponsorDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatNewSponsorDetails create() => LiveChatNewSponsorDetails._();
  @$core.override
  LiveChatNewSponsorDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatNewSponsorDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatNewSponsorDetails>(create);
  static LiveChatNewSponsorDetails? _defaultInstance;

  /// The name of the Level that the viewer just had joined. The Level names
  /// are defined by the YouTube channel offering the Membership.
  ///
  /// In some situations this field isn't filled.
  @$pb.TagNumber(1)
  $core.String get memberLevelName => $_getSZ(0);
  @$pb.TagNumber(1)
  set memberLevelName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberLevelName() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberLevelName() => $_clearField(1);

  /// If the viewer just had upgraded from a lower level. For viewers that
  /// were not members at the time of purchase, this field is false.
  @$pb.TagNumber(2)
  $core.bool get isUpgrade => $_getBF(1);
  @$pb.TagNumber(2)
  set isUpgrade($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIsUpgrade() => $_has(1);
  @$pb.TagNumber(2)
  void clearIsUpgrade() => $_clearField(2);
}

class LiveChatMemberMilestoneChatDetails extends $pb.GeneratedMessage {
  factory LiveChatMemberMilestoneChatDetails({
    $core.String? memberLevelName,
    $core.int? memberMonth,
    $core.String? userComment,
  }) {
    final result = create();
    if (memberLevelName != null) result.memberLevelName = memberLevelName;
    if (memberMonth != null) result.memberMonth = memberMonth;
    if (userComment != null) result.userComment = userComment;
    return result;
  }

  LiveChatMemberMilestoneChatDetails._();

  factory LiveChatMemberMilestoneChatDetails.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMemberMilestoneChatDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMemberMilestoneChatDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'memberLevelName')
    ..aI(2, _omitFieldNames ? '' : 'memberMonth',
        fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'userComment')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMemberMilestoneChatDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMemberMilestoneChatDetails copyWith(
          void Function(LiveChatMemberMilestoneChatDetails) updates) =>
      super.copyWith((message) =>
              updates(message as LiveChatMemberMilestoneChatDetails))
          as LiveChatMemberMilestoneChatDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMemberMilestoneChatDetails create() =>
      LiveChatMemberMilestoneChatDetails._();
  @$core.override
  LiveChatMemberMilestoneChatDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMemberMilestoneChatDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMemberMilestoneChatDetails>(
          create);
  static LiveChatMemberMilestoneChatDetails? _defaultInstance;

  /// The name of the Level at which the viever is a member. The Level names
  /// are defined by the YouTube channel offering the Membership.
  ///
  /// In some situations this field isn't filled.
  @$pb.TagNumber(1)
  $core.String get memberLevelName => $_getSZ(0);
  @$pb.TagNumber(1)
  set memberLevelName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberLevelName() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberLevelName() => $_clearField(1);

  /// The total amount of months (rounded up) the viewer has been a member
  /// that granted them this Member Milestone Chat. This is the same
  /// number of months as is being displayed to YouTube users.
  @$pb.TagNumber(2)
  $core.int get memberMonth => $_getIZ(1);
  @$pb.TagNumber(2)
  set memberMonth($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMemberMonth() => $_has(1);
  @$pb.TagNumber(2)
  void clearMemberMonth() => $_clearField(2);

  /// The comment added by the member to this Member Milestone Chat.
  ///
  /// This field is empty for messages without a comment from the member.
  @$pb.TagNumber(3)
  $core.String get userComment => $_getSZ(2);
  @$pb.TagNumber(3)
  set userComment($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasUserComment() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserComment() => $_clearField(3);
}

class LiveChatMembershipGiftingDetails extends $pb.GeneratedMessage {
  factory LiveChatMembershipGiftingDetails({
    $core.int? giftMembershipsCount,
    $core.String? giftMembershipsLevelName,
  }) {
    final result = create();
    if (giftMembershipsCount != null)
      result.giftMembershipsCount = giftMembershipsCount;
    if (giftMembershipsLevelName != null)
      result.giftMembershipsLevelName = giftMembershipsLevelName;
    return result;
  }

  LiveChatMembershipGiftingDetails._();

  factory LiveChatMembershipGiftingDetails.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatMembershipGiftingDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatMembershipGiftingDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'giftMembershipsCount')
    ..aOS(2, _omitFieldNames ? '' : 'giftMembershipsLevelName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMembershipGiftingDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatMembershipGiftingDetails copyWith(
          void Function(LiveChatMembershipGiftingDetails) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatMembershipGiftingDetails))
          as LiveChatMembershipGiftingDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatMembershipGiftingDetails create() =>
      LiveChatMembershipGiftingDetails._();
  @$core.override
  LiveChatMembershipGiftingDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatMembershipGiftingDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatMembershipGiftingDetails>(
          create);
  static LiveChatMembershipGiftingDetails? _defaultInstance;

  /// The number of gift memberships purchased by the user.
  @$pb.TagNumber(1)
  $core.int get giftMembershipsCount => $_getIZ(0);
  @$pb.TagNumber(1)
  set giftMembershipsCount($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGiftMembershipsCount() => $_has(0);
  @$pb.TagNumber(1)
  void clearGiftMembershipsCount() => $_clearField(1);

  /// The name of the level of the gift memberships purchased by the user. The
  /// Level names are defined by the YouTube channel offering the Membership.
  ///
  /// In some situations this field isn't filled.
  @$pb.TagNumber(2)
  $core.String get giftMembershipsLevelName => $_getSZ(1);
  @$pb.TagNumber(2)
  set giftMembershipsLevelName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGiftMembershipsLevelName() => $_has(1);
  @$pb.TagNumber(2)
  void clearGiftMembershipsLevelName() => $_clearField(2);
}

class LiveChatGiftMembershipReceivedDetails extends $pb.GeneratedMessage {
  factory LiveChatGiftMembershipReceivedDetails({
    $core.String? memberLevelName,
    $core.String? gifterChannelId,
    $core.String? associatedMembershipGiftingMessageId,
  }) {
    final result = create();
    if (memberLevelName != null) result.memberLevelName = memberLevelName;
    if (gifterChannelId != null) result.gifterChannelId = gifterChannelId;
    if (associatedMembershipGiftingMessageId != null)
      result.associatedMembershipGiftingMessageId =
          associatedMembershipGiftingMessageId;
    return result;
  }

  LiveChatGiftMembershipReceivedDetails._();

  factory LiveChatGiftMembershipReceivedDetails.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatGiftMembershipReceivedDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatGiftMembershipReceivedDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'memberLevelName')
    ..aOS(2, _omitFieldNames ? '' : 'gifterChannelId')
    ..aOS(3, _omitFieldNames ? '' : 'associatedMembershipGiftingMessageId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatGiftMembershipReceivedDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatGiftMembershipReceivedDetails copyWith(
          void Function(LiveChatGiftMembershipReceivedDetails) updates) =>
      super.copyWith((message) =>
              updates(message as LiveChatGiftMembershipReceivedDetails))
          as LiveChatGiftMembershipReceivedDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatGiftMembershipReceivedDetails create() =>
      LiveChatGiftMembershipReceivedDetails._();
  @$core.override
  LiveChatGiftMembershipReceivedDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatGiftMembershipReceivedDetails getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          LiveChatGiftMembershipReceivedDetails>(create);
  static LiveChatGiftMembershipReceivedDetails? _defaultInstance;

  /// The name of the Level at which the viewer is a member. This matches the
  /// `snippet.membershipGiftingDetails.giftMembershipsLevelName` of the
  /// associated membership gifting message. The Level names are defined by the
  /// YouTube channel offering the Membership.
  ///
  /// In some situations this field isn't filled.
  @$pb.TagNumber(1)
  $core.String get memberLevelName => $_getSZ(0);
  @$pb.TagNumber(1)
  set memberLevelName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMemberLevelName() => $_has(0);
  @$pb.TagNumber(1)
  void clearMemberLevelName() => $_clearField(1);

  /// The ID of the user that made the membership gifting purchase. This matches
  /// the `snippet.authorChannelId` of the associated membership gifting message.
  @$pb.TagNumber(2)
  $core.String get gifterChannelId => $_getSZ(1);
  @$pb.TagNumber(2)
  set gifterChannelId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGifterChannelId() => $_has(1);
  @$pb.TagNumber(2)
  void clearGifterChannelId() => $_clearField(2);

  /// The ID of the membership gifting message that is related to this gift
  /// membership. This ID will always refer to a message whose type is
  /// 'membershipGiftingEvent'.
  @$pb.TagNumber(3)
  $core.String get associatedMembershipGiftingMessageId => $_getSZ(2);
  @$pb.TagNumber(3)
  set associatedMembershipGiftingMessageId($core.String value) =>
      $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAssociatedMembershipGiftingMessageId() => $_has(2);
  @$pb.TagNumber(3)
  void clearAssociatedMembershipGiftingMessageId() => $_clearField(3);
}

class LiveChatPollDetails_PollMetadata_PollOption extends $pb.GeneratedMessage {
  factory LiveChatPollDetails_PollMetadata_PollOption({
    $core.String? optionText,
    $fixnum.Int64? tally,
  }) {
    final result = create();
    if (optionText != null) result.optionText = optionText;
    if (tally != null) result.tally = tally;
    return result;
  }

  LiveChatPollDetails_PollMetadata_PollOption._();

  factory LiveChatPollDetails_PollMetadata_PollOption.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatPollDetails_PollMetadata_PollOption.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatPollDetails.PollMetadata.PollOption',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'optionText')
    ..aInt64(2, _omitFieldNames ? '' : 'tally')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails_PollMetadata_PollOption clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails_PollMetadata_PollOption copyWith(
          void Function(LiveChatPollDetails_PollMetadata_PollOption) updates) =>
      super.copyWith((message) =>
              updates(message as LiveChatPollDetails_PollMetadata_PollOption))
          as LiveChatPollDetails_PollMetadata_PollOption;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails_PollMetadata_PollOption create() =>
      LiveChatPollDetails_PollMetadata_PollOption._();
  @$core.override
  LiveChatPollDetails_PollMetadata_PollOption createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails_PollMetadata_PollOption getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          LiveChatPollDetails_PollMetadata_PollOption>(create);
  static LiveChatPollDetails_PollMetadata_PollOption? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get optionText => $_getSZ(0);
  @$pb.TagNumber(1)
  set optionText($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasOptionText() => $_has(0);
  @$pb.TagNumber(1)
  void clearOptionText() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get tally => $_getI64(1);
  @$pb.TagNumber(2)
  set tally($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTally() => $_has(1);
  @$pb.TagNumber(2)
  void clearTally() => $_clearField(2);
}

class LiveChatPollDetails_PollMetadata extends $pb.GeneratedMessage {
  factory LiveChatPollDetails_PollMetadata({
    $core.String? questionText,
    $core.Iterable<LiveChatPollDetails_PollMetadata_PollOption>? options,
  }) {
    final result = create();
    if (questionText != null) result.questionText = questionText;
    if (options != null) result.options.addAll(options);
    return result;
  }

  LiveChatPollDetails_PollMetadata._();

  factory LiveChatPollDetails_PollMetadata.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatPollDetails_PollMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatPollDetails.PollMetadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'questionText')
    ..pPM<LiveChatPollDetails_PollMetadata_PollOption>(
        2, _omitFieldNames ? '' : 'options',
        subBuilder: LiveChatPollDetails_PollMetadata_PollOption.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails_PollMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails_PollMetadata copyWith(
          void Function(LiveChatPollDetails_PollMetadata) updates) =>
      super.copyWith(
              (message) => updates(message as LiveChatPollDetails_PollMetadata))
          as LiveChatPollDetails_PollMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails_PollMetadata create() =>
      LiveChatPollDetails_PollMetadata._();
  @$core.override
  LiveChatPollDetails_PollMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails_PollMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatPollDetails_PollMetadata>(
          create);
  static LiveChatPollDetails_PollMetadata? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get questionText => $_getSZ(0);
  @$pb.TagNumber(1)
  set questionText($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQuestionText() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuestionText() => $_clearField(1);

  /// The options will be returned in the order that is displayed in 1P
  @$pb.TagNumber(2)
  $pb.PbList<LiveChatPollDetails_PollMetadata_PollOption> get options =>
      $_getList(1);
}

/// Current point in the polls lifecycle.
class LiveChatPollDetails_PollStatusWrapper extends $pb.GeneratedMessage {
  factory LiveChatPollDetails_PollStatusWrapper() => create();

  LiveChatPollDetails_PollStatusWrapper._();

  factory LiveChatPollDetails_PollStatusWrapper.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatPollDetails_PollStatusWrapper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatPollDetails.PollStatusWrapper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails_PollStatusWrapper clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails_PollStatusWrapper copyWith(
          void Function(LiveChatPollDetails_PollStatusWrapper) updates) =>
      super.copyWith((message) =>
              updates(message as LiveChatPollDetails_PollStatusWrapper))
          as LiveChatPollDetails_PollStatusWrapper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails_PollStatusWrapper create() =>
      LiveChatPollDetails_PollStatusWrapper._();
  @$core.override
  LiveChatPollDetails_PollStatusWrapper createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails_PollStatusWrapper getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          LiveChatPollDetails_PollStatusWrapper>(create);
  static LiveChatPollDetails_PollStatusWrapper? _defaultInstance;
}

class LiveChatPollDetails extends $pb.GeneratedMessage {
  factory LiveChatPollDetails({
    LiveChatPollDetails_PollMetadata? metadata,
    LiveChatPollDetails_PollStatusWrapper_PollStatus? status,
  }) {
    final result = create();
    if (metadata != null) result.metadata = metadata;
    if (status != null) result.status = status;
    return result;
  }

  LiveChatPollDetails._();

  factory LiveChatPollDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatPollDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatPollDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOM<LiveChatPollDetails_PollMetadata>(
        1, _omitFieldNames ? '' : 'metadata',
        subBuilder: LiveChatPollDetails_PollMetadata.create)
    ..aE<LiveChatPollDetails_PollStatusWrapper_PollStatus>(
        2, _omitFieldNames ? '' : 'status',
        enumValues: LiveChatPollDetails_PollStatusWrapper_PollStatus.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatPollDetails copyWith(void Function(LiveChatPollDetails) updates) =>
      super.copyWith((message) => updates(message as LiveChatPollDetails))
          as LiveChatPollDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails create() => LiveChatPollDetails._();
  @$core.override
  LiveChatPollDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatPollDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatPollDetails>(create);
  static LiveChatPollDetails? _defaultInstance;

  @$pb.TagNumber(1)
  LiveChatPollDetails_PollMetadata get metadata => $_getN(0);
  @$pb.TagNumber(1)
  set metadata(LiveChatPollDetails_PollMetadata value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMetadata() => $_has(0);
  @$pb.TagNumber(1)
  void clearMetadata() => $_clearField(1);
  @$pb.TagNumber(1)
  LiveChatPollDetails_PollMetadata ensureMetadata() => $_ensure(0);

  @$pb.TagNumber(2)
  LiveChatPollDetails_PollStatusWrapper_PollStatus get status => $_getN(1);
  @$pb.TagNumber(2)
  set status(LiveChatPollDetails_PollStatusWrapper_PollStatus value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => $_clearField(2);
}

class LiveChatGiftDetails extends $pb.GeneratedMessage {
  factory LiveChatGiftDetails({
    $core.String? giftName,
    $1.Duration? giftDuration,
    $core.int? jewelsAmount,
    $core.String? giftUrl,
    $core.String? altText,
    $core.String? language,
    $core.bool? hasVisualEffect,
    $core.int? comboCount,
  }) {
    final result = create();
    if (giftName != null) result.giftName = giftName;
    if (giftDuration != null) result.giftDuration = giftDuration;
    if (jewelsAmount != null) result.jewelsAmount = jewelsAmount;
    if (giftUrl != null) result.giftUrl = giftUrl;
    if (altText != null) result.altText = altText;
    if (language != null) result.language = language;
    if (hasVisualEffect != null) result.hasVisualEffect = hasVisualEffect;
    if (comboCount != null) result.comboCount = comboCount;
    return result;
  }

  LiveChatGiftDetails._();

  factory LiveChatGiftDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveChatGiftDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveChatGiftDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'giftName')
    ..aOM<$1.Duration>(2, _omitFieldNames ? '' : 'giftDuration',
        subBuilder: $1.Duration.create)
    ..aI(3, _omitFieldNames ? '' : 'jewelsAmount')
    ..aOS(4, _omitFieldNames ? '' : 'giftUrl')
    ..aOS(5, _omitFieldNames ? '' : 'altText')
    ..aOS(6, _omitFieldNames ? '' : 'language')
    ..aOB(7, _omitFieldNames ? '' : 'hasVisualEffect')
    ..aI(8, _omitFieldNames ? '' : 'comboCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatGiftDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveChatGiftDetails copyWith(void Function(LiveChatGiftDetails) updates) =>
      super.copyWith((message) => updates(message as LiveChatGiftDetails))
          as LiveChatGiftDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveChatGiftDetails create() => LiveChatGiftDetails._();
  @$core.override
  LiveChatGiftDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveChatGiftDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveChatGiftDetails>(create);
  static LiveChatGiftDetails? _defaultInstance;

  /// The name of the gift.
  @$pb.TagNumber(1)
  $core.String get giftName => $_getSZ(0);
  @$pb.TagNumber(1)
  set giftName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGiftName() => $_has(0);
  @$pb.TagNumber(1)
  void clearGiftName() => $_clearField(1);

  /// The duration of the gift.
  @$pb.TagNumber(2)
  $1.Duration get giftDuration => $_getN(1);
  @$pb.TagNumber(2)
  set giftDuration($1.Duration value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasGiftDuration() => $_has(1);
  @$pb.TagNumber(2)
  void clearGiftDuration() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Duration ensureGiftDuration() => $_ensure(1);

  /// The value of the gift in jewels.
  @$pb.TagNumber(3)
  $core.int get jewelsAmount => $_getIZ(2);
  @$pb.TagNumber(3)
  set jewelsAmount($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasJewelsAmount() => $_has(2);
  @$pb.TagNumber(3)
  void clearJewelsAmount() => $_clearField(3);

  /// The URL of the gift image.
  @$pb.TagNumber(4)
  $core.String get giftUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set giftUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGiftUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearGiftUrl() => $_clearField(4);

  /// The alternative text to be used for accessibility.
  @$pb.TagNumber(5)
  $core.String get altText => $_getSZ(4);
  @$pb.TagNumber(5)
  set altText($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAltText() => $_has(4);
  @$pb.TagNumber(5)
  void clearAltText() => $_clearField(5);

  /// The BCP-47 language code of the gift.
  @$pb.TagNumber(6)
  $core.String get language => $_getSZ(5);
  @$pb.TagNumber(6)
  set language($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLanguage() => $_has(5);
  @$pb.TagNumber(6)
  void clearLanguage() => $_clearField(6);

  /// Whether the gift involves a visual effect.
  @$pb.TagNumber(7)
  $core.bool get hasVisualEffect => $_getBF(6);
  @$pb.TagNumber(7)
  set hasVisualEffect($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHasVisualEffect() => $_has(6);
  @$pb.TagNumber(7)
  void clearHasVisualEffect() => $_clearField(7);

  /// The number of times the gift has been sent in a row.
  @$pb.TagNumber(8)
  $core.int get comboCount => $_getIZ(7);
  @$pb.TagNumber(8)
  set comboCount($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasComboCount() => $_has(7);
  @$pb.TagNumber(8)
  void clearComboCount() => $_clearField(8);
}

class SuperChatEventSnippet extends $pb.GeneratedMessage {
  factory SuperChatEventSnippet({
    ChannelProfileDetails? supporterDetails,
    $core.String? commentText,
    $core.String? createdAt,
    $fixnum.Int64? amountMicros,
    $core.String? currency,
    $core.String? displayString,
    $core.int? messageType,
    $core.bool? isSuperStickerEvent,
    SuperStickerMetadata? superStickerMetadata,
    $core.String? channelId,
  }) {
    final result = create();
    if (supporterDetails != null) result.supporterDetails = supporterDetails;
    if (commentText != null) result.commentText = commentText;
    if (createdAt != null) result.createdAt = createdAt;
    if (amountMicros != null) result.amountMicros = amountMicros;
    if (currency != null) result.currency = currency;
    if (displayString != null) result.displayString = displayString;
    if (messageType != null) result.messageType = messageType;
    if (isSuperStickerEvent != null)
      result.isSuperStickerEvent = isSuperStickerEvent;
    if (superStickerMetadata != null)
      result.superStickerMetadata = superStickerMetadata;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  SuperChatEventSnippet._();

  factory SuperChatEventSnippet.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuperChatEventSnippet.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuperChatEventSnippet',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOM<ChannelProfileDetails>(2, _omitFieldNames ? '' : 'supporterDetails',
        subBuilder: ChannelProfileDetails.create)
    ..aOS(3, _omitFieldNames ? '' : 'commentText')
    ..aOS(4, _omitFieldNames ? '' : 'createdAt')
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'amountMicros', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(6, _omitFieldNames ? '' : 'currency')
    ..aOS(7, _omitFieldNames ? '' : 'displayString')
    ..aI(8, _omitFieldNames ? '' : 'messageType',
        fieldType: $pb.PbFieldType.OU3)
    ..aOB(11, _omitFieldNames ? '' : 'isSuperStickerEvent')
    ..aOM<SuperStickerMetadata>(
        12, _omitFieldNames ? '' : 'superStickerMetadata',
        subBuilder: SuperStickerMetadata.create)
    ..aOS(101, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuperChatEventSnippet clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuperChatEventSnippet copyWith(
          void Function(SuperChatEventSnippet) updates) =>
      super.copyWith((message) => updates(message as SuperChatEventSnippet))
          as SuperChatEventSnippet;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuperChatEventSnippet create() => SuperChatEventSnippet._();
  @$core.override
  SuperChatEventSnippet createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuperChatEventSnippet getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuperChatEventSnippet>(create);
  static SuperChatEventSnippet? _defaultInstance;

  /// Details about the supporter.
  @$pb.TagNumber(2)
  ChannelProfileDetails get supporterDetails => $_getN(0);
  @$pb.TagNumber(2)
  set supporterDetails(ChannelProfileDetails value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasSupporterDetails() => $_has(0);
  @$pb.TagNumber(2)
  void clearSupporterDetails() => $_clearField(2);
  @$pb.TagNumber(2)
  ChannelProfileDetails ensureSupporterDetails() => $_ensure(0);

  /// The text contents of the comment left by the user.
  @$pb.TagNumber(3)
  $core.String get commentText => $_getSZ(1);
  @$pb.TagNumber(3)
  set commentText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasCommentText() => $_has(1);
  @$pb.TagNumber(3)
  void clearCommentText() => $_clearField(3);

  /// The date and time when the event occurred. The value is
  /// specified in <a href="//www.w3.org/TR/NOTE-datetime">ISO 8601</a>
  /// format.
  @$pb.TagNumber(4)
  $core.String get createdAt => $_getSZ(2);
  @$pb.TagNumber(4)
  set createdAt($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(2);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);

  /// The purchase amount, in micros of the purchase currency.  For example, 1 is
  /// represented as 1000000.
  @$pb.TagNumber(5)
  $fixnum.Int64 get amountMicros => $_getI64(3);
  @$pb.TagNumber(5)
  set amountMicros($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(5)
  $core.bool hasAmountMicros() => $_has(3);
  @$pb.TagNumber(5)
  void clearAmountMicros() => $_clearField(5);

  /// The currency in which the purchase was made.  ISO 4217.
  @$pb.TagNumber(6)
  $core.String get currency => $_getSZ(4);
  @$pb.TagNumber(6)
  set currency($core.String value) => $_setString(4, value);
  @$pb.TagNumber(6)
  $core.bool hasCurrency() => $_has(4);
  @$pb.TagNumber(6)
  void clearCurrency() => $_clearField(6);

  /// A rendered string that displays the purchase amount and currency
  /// (e.g., "$1.00").  The string is rendered for the given language.
  @$pb.TagNumber(7)
  $core.String get displayString => $_getSZ(5);
  @$pb.TagNumber(7)
  set displayString($core.String value) => $_setString(5, value);
  @$pb.TagNumber(7)
  $core.bool hasDisplayString() => $_has(5);
  @$pb.TagNumber(7)
  void clearDisplayString() => $_clearField(7);

  /// The tier for the paid message, which is based on the amount of money spent
  /// to purchase the message.
  @$pb.TagNumber(8)
  $core.int get messageType => $_getIZ(6);
  @$pb.TagNumber(8)
  set messageType($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(8)
  $core.bool hasMessageType() => $_has(6);
  @$pb.TagNumber(8)
  void clearMessageType() => $_clearField(8);

  /// True if this event is a Super Sticker event.
  @$pb.TagNumber(11)
  $core.bool get isSuperStickerEvent => $_getBF(7);
  @$pb.TagNumber(11)
  set isSuperStickerEvent($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(11)
  $core.bool hasIsSuperStickerEvent() => $_has(7);
  @$pb.TagNumber(11)
  void clearIsSuperStickerEvent() => $_clearField(11);

  /// If this event is a Super Sticker event, this field will contain metadata
  /// about the Super Sticker.
  @$pb.TagNumber(12)
  SuperStickerMetadata get superStickerMetadata => $_getN(8);
  @$pb.TagNumber(12)
  set superStickerMetadata(SuperStickerMetadata value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasSuperStickerMetadata() => $_has(8);
  @$pb.TagNumber(12)
  void clearSuperStickerMetadata() => $_clearField(12);
  @$pb.TagNumber(12)
  SuperStickerMetadata ensureSuperStickerMetadata() => $_ensure(8);

  /// Channel ID where the event occurred.
  @$pb.TagNumber(101)
  $core.String get channelId => $_getSZ(9);
  @$pb.TagNumber(101)
  set channelId($core.String value) => $_setString(9, value);
  @$pb.TagNumber(101)
  $core.bool hasChannelId() => $_has(9);
  @$pb.TagNumber(101)
  void clearChannelId() => $_clearField(101);
}

class SuperStickerMetadata extends $pb.GeneratedMessage {
  factory SuperStickerMetadata({
    $core.String? stickerId,
    $core.String? altText,
    $core.String? altTextLanguage,
  }) {
    final result = create();
    if (stickerId != null) result.stickerId = stickerId;
    if (altText != null) result.altText = altText;
    if (altTextLanguage != null) result.altTextLanguage = altTextLanguage;
    return result;
  }

  SuperStickerMetadata._();

  factory SuperStickerMetadata.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SuperStickerMetadata.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SuperStickerMetadata',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'stickerId')
    ..aOS(2, _omitFieldNames ? '' : 'altText')
    ..aOS(3, _omitFieldNames ? '' : 'altTextLanguage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuperStickerMetadata clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SuperStickerMetadata copyWith(void Function(SuperStickerMetadata) updates) =>
      super.copyWith((message) => updates(message as SuperStickerMetadata))
          as SuperStickerMetadata;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SuperStickerMetadata create() => SuperStickerMetadata._();
  @$core.override
  SuperStickerMetadata createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SuperStickerMetadata getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SuperStickerMetadata>(create);
  static SuperStickerMetadata? _defaultInstance;

  /// Unique identifier of the Super Sticker. This is a shorter form of the
  /// alt_text that includes pack name and a recognizable characteristic of the
  /// sticker.
  @$pb.TagNumber(1)
  $core.String get stickerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set stickerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStickerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearStickerId() => $_clearField(1);

  /// Internationalized alt text that describes the sticker image and any
  /// animation associated with it.
  @$pb.TagNumber(2)
  $core.String get altText => $_getSZ(1);
  @$pb.TagNumber(2)
  set altText($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAltText() => $_has(1);
  @$pb.TagNumber(2)
  void clearAltText() => $_clearField(2);

  /// Specifies the localization language in which the alt text is returned.
  @$pb.TagNumber(3)
  $core.String get altTextLanguage => $_getSZ(2);
  @$pb.TagNumber(3)
  set altTextLanguage($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAltTextLanguage() => $_has(2);
  @$pb.TagNumber(3)
  void clearAltTextLanguage() => $_clearField(3);
}

class ChannelProfileDetails extends $pb.GeneratedMessage {
  factory ChannelProfileDetails({
    $core.String? channelUrl,
    $core.String? displayName,
    $core.String? profileImageUrl,
    $core.String? channelId,
  }) {
    final result = create();
    if (channelUrl != null) result.channelUrl = channelUrl;
    if (displayName != null) result.displayName = displayName;
    if (profileImageUrl != null) result.profileImageUrl = profileImageUrl;
    if (channelId != null) result.channelId = channelId;
    return result;
  }

  ChannelProfileDetails._();

  factory ChannelProfileDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ChannelProfileDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ChannelProfileDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'channelUrl')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..aOS(4, _omitFieldNames ? '' : 'profileImageUrl')
    ..aOS(101, _omitFieldNames ? '' : 'channelId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelProfileDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ChannelProfileDetails copyWith(
          void Function(ChannelProfileDetails) updates) =>
      super.copyWith((message) => updates(message as ChannelProfileDetails))
          as ChannelProfileDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ChannelProfileDetails create() => ChannelProfileDetails._();
  @$core.override
  ChannelProfileDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ChannelProfileDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ChannelProfileDetails>(create);
  static ChannelProfileDetails? _defaultInstance;

  /// The channel's URL.
  @$pb.TagNumber(2)
  $core.String get channelUrl => $_getSZ(0);
  @$pb.TagNumber(2)
  set channelUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(2)
  $core.bool hasChannelUrl() => $_has(0);
  @$pb.TagNumber(2)
  void clearChannelUrl() => $_clearField(2);

  /// The channel's display name.
  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);

  /// The channels's avatar URL.
  @$pb.TagNumber(4)
  $core.String get profileImageUrl => $_getSZ(2);
  @$pb.TagNumber(4)
  set profileImageUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(4)
  $core.bool hasProfileImageUrl() => $_has(2);
  @$pb.TagNumber(4)
  void clearProfileImageUrl() => $_clearField(4);

  /// The YouTube channel ID.
  @$pb.TagNumber(101)
  $core.String get channelId => $_getSZ(3);
  @$pb.TagNumber(101)
  set channelId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(101)
  $core.bool hasChannelId() => $_has(3);
  @$pb.TagNumber(101)
  void clearChannelId() => $_clearField(101);
}

/// Paging details for lists of resources, including total number of items
/// available and number of resources returned in a single page.
class PageInfo extends $pb.GeneratedMessage {
  factory PageInfo({
    $core.int? totalResults,
    $core.int? resultsPerPage,
  }) {
    final result = create();
    if (totalResults != null) result.totalResults = totalResults;
    if (resultsPerPage != null) result.resultsPerPage = resultsPerPage;
    return result;
  }

  PageInfo._();

  factory PageInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PageInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PageInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'youtube.api.v3'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'totalResults')
    ..aI(2, _omitFieldNames ? '' : 'resultsPerPage')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageInfo copyWith(void Function(PageInfo) updates) =>
      super.copyWith((message) => updates(message as PageInfo)) as PageInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PageInfo create() => PageInfo._();
  @$core.override
  PageInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PageInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PageInfo>(create);
  static PageInfo? _defaultInstance;

  /// The total number of results in the result set.
  @$pb.TagNumber(1)
  $core.int get totalResults => $_getIZ(0);
  @$pb.TagNumber(1)
  set totalResults($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotalResults() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotalResults() => $_clearField(1);

  /// The number of results included in the API response.
  @$pb.TagNumber(2)
  $core.int get resultsPerPage => $_getIZ(1);
  @$pb.TagNumber(2)
  set resultsPerPage($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasResultsPerPage() => $_has(1);
  @$pb.TagNumber(2)
  void clearResultsPerPage() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
