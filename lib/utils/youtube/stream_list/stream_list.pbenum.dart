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

import 'package:protobuf/protobuf.dart' as $pb;

class LiveChatMessageSnippet_TypeWrapper_Type extends $pb.ProtobufEnum {
  static const LiveChatMessageSnippet_TypeWrapper_Type INVALID_TYPE =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          0, _omitEnumNames ? '' : 'INVALID_TYPE');
  static const LiveChatMessageSnippet_TypeWrapper_Type TEXT_MESSAGE_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          1, _omitEnumNames ? '' : 'TEXT_MESSAGE_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type TOMBSTONE =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          2, _omitEnumNames ? '' : 'TOMBSTONE');
  static const LiveChatMessageSnippet_TypeWrapper_Type FAN_FUNDING_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          3, _omitEnumNames ? '' : 'FAN_FUNDING_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type CHAT_ENDED_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          4, _omitEnumNames ? '' : 'CHAT_ENDED_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type
      SPONSOR_ONLY_MODE_STARTED_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          5, _omitEnumNames ? '' : 'SPONSOR_ONLY_MODE_STARTED_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type
      SPONSOR_ONLY_MODE_ENDED_EVENT = LiveChatMessageSnippet_TypeWrapper_Type._(
          6, _omitEnumNames ? '' : 'SPONSOR_ONLY_MODE_ENDED_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type NEW_SPONSOR_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          7, _omitEnumNames ? '' : 'NEW_SPONSOR_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type
      MEMBER_MILESTONE_CHAT_EVENT = LiveChatMessageSnippet_TypeWrapper_Type._(
          17, _omitEnumNames ? '' : 'MEMBER_MILESTONE_CHAT_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type
      MEMBERSHIP_GIFTING_EVENT = LiveChatMessageSnippet_TypeWrapper_Type._(
          18, _omitEnumNames ? '' : 'MEMBERSHIP_GIFTING_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type
      GIFT_MEMBERSHIP_RECEIVED_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          19, _omitEnumNames ? '' : 'GIFT_MEMBERSHIP_RECEIVED_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type USER_BANNED_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          10, _omitEnumNames ? '' : 'USER_BANNED_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type SUPER_CHAT_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          15, _omitEnumNames ? '' : 'SUPER_CHAT_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type SUPER_STICKER_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          16, _omitEnumNames ? '' : 'SUPER_STICKER_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type POLL_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          20, _omitEnumNames ? '' : 'POLL_EVENT');
  static const LiveChatMessageSnippet_TypeWrapper_Type GIFT_EVENT =
      LiveChatMessageSnippet_TypeWrapper_Type._(
          21, _omitEnumNames ? '' : 'GIFT_EVENT');

  static const $core.List<LiveChatMessageSnippet_TypeWrapper_Type> values =
      <LiveChatMessageSnippet_TypeWrapper_Type>[
    INVALID_TYPE,
    TEXT_MESSAGE_EVENT,
    TOMBSTONE,
    FAN_FUNDING_EVENT,
    CHAT_ENDED_EVENT,
    SPONSOR_ONLY_MODE_STARTED_EVENT,
    SPONSOR_ONLY_MODE_ENDED_EVENT,
    NEW_SPONSOR_EVENT,
    MEMBER_MILESTONE_CHAT_EVENT,
    MEMBERSHIP_GIFTING_EVENT,
    GIFT_MEMBERSHIP_RECEIVED_EVENT,
    USER_BANNED_EVENT,
    SUPER_CHAT_EVENT,
    SUPER_STICKER_EVENT,
    POLL_EVENT,
    GIFT_EVENT,
  ];

  static final $core.List<LiveChatMessageSnippet_TypeWrapper_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 21);
  static LiveChatMessageSnippet_TypeWrapper_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LiveChatMessageSnippet_TypeWrapper_Type._(super.value, super.name);
}

class LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType
    extends $pb.ProtobufEnum {
  static const LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType
      PERMANENT = LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType._(
          1, _omitEnumNames ? '' : 'PERMANENT');
  static const LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType
      TEMPORARY = LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType._(
          2, _omitEnumNames ? '' : 'TEMPORARY');

  static const $core
      .List<LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType>
      values = <LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType>[
    PERMANENT,
    TEMPORARY,
  ];

  static final $core
      .Map<$core.int, LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType>
      _byValue = $pb.ProtobufEnum.initByValue(values);
  static LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType? valueOf(
          $core.int value) =>
      _byValue[value];

  const LiveChatUserBannedMessageDetails_BanTypeWrapper_BanType._(
      super.value, super.name);
}

class LiveChatPollDetails_PollStatusWrapper_PollStatus
    extends $pb.ProtobufEnum {
  static const LiveChatPollDetails_PollStatusWrapper_PollStatus UNKNOWN =
      LiveChatPollDetails_PollStatusWrapper_PollStatus._(
          0, _omitEnumNames ? '' : 'UNKNOWN');
  static const LiveChatPollDetails_PollStatusWrapper_PollStatus ACTIVE =
      LiveChatPollDetails_PollStatusWrapper_PollStatus._(
          1, _omitEnumNames ? '' : 'ACTIVE');
  static const LiveChatPollDetails_PollStatusWrapper_PollStatus CLOSED =
      LiveChatPollDetails_PollStatusWrapper_PollStatus._(
          2, _omitEnumNames ? '' : 'CLOSED');

  static const $core.List<LiveChatPollDetails_PollStatusWrapper_PollStatus>
      values = <LiveChatPollDetails_PollStatusWrapper_PollStatus>[
    UNKNOWN,
    ACTIVE,
    CLOSED,
  ];

  static final $core.List<LiveChatPollDetails_PollStatusWrapper_PollStatus?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static LiveChatPollDetails_PollStatusWrapper_PollStatus? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const LiveChatPollDetails_PollStatusWrapper_PollStatus._(
      super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
