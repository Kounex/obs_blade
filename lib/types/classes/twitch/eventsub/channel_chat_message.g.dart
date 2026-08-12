// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageEvent _$ChatMessageEventFromJson(
  Map<String, dynamic> json,
) => _ChatMessageEvent(
  broadcasterUserId: json['broadcaster_user_id'] as String,
  chatterUserId: json['chatter_user_id'] as String,
  chatterUserLogin: json['chatter_user_login'] as String,
  chatterUserName: json['chatter_user_name'] as String,
  messageId: json['message_id'] as String,
  message: ChatMessageText.fromJson(json['message'] as Map<String, dynamic>),
  color: json['color'] as String?,
  badges:
      (json['badges'] as List<dynamic>?)
          ?.map((e) => ChatMessageBadge.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ChatMessageBadge>[],
  messageType: json['message_type'] as String? ?? 'text',
  reply: json['reply'] == null
      ? null
      : ChatMessageReply.fromJson(json['reply'] as Map<String, dynamic>),
  sourceBroadcasterUserId: json['source_broadcaster_user_id'] as String?,
  sourceBroadcasterUserLogin: json['source_broadcaster_user_login'] as String?,
  sourceBroadcasterUserName: json['source_broadcaster_user_name'] as String?,
);

_ChatMessageText _$ChatMessageTextFromJson(Map<String, dynamic> json) =>
    _ChatMessageText(
      text: json['text'] as String,
      fragments:
          (json['fragments'] as List<dynamic>?)
              ?.map(
                (e) => ChatMessageFragment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <ChatMessageFragment>[],
    );

_ChatMessageFragment _$ChatMessageFragmentFromJson(Map<String, dynamic> json) =>
    _ChatMessageFragment(
      type: json['type'] as String,
      text: json['text'] as String,
      emote: json['emote'] == null
          ? null
          : ChatFragmentEmote.fromJson(json['emote'] as Map<String, dynamic>),
      mention: json['mention'] == null
          ? null
          : ChatFragmentMention.fromJson(
              json['mention'] as Map<String, dynamic>,
            ),
      gif: json['gif'] == null
          ? null
          : ChatFragmentGif.fromJson(json['gif'] as Map<String, dynamic>),
    );

_ChatFragmentGif _$ChatFragmentGifFromJson(Map<String, dynamic> json) =>
    _ChatFragmentGif(
      gifId: json['gif_id'] as String,
      url: json['url'] as String,
    );

_ChatFragmentEmote _$ChatFragmentEmoteFromJson(Map<String, dynamic> json) =>
    _ChatFragmentEmote(id: json['id'] as String);

_ChatFragmentMention _$ChatFragmentMentionFromJson(Map<String, dynamic> json) =>
    _ChatFragmentMention(
      userId: json['user_id'] as String,
      userLogin: json['user_login'] as String,
      userName: json['user_name'] as String,
    );

_ChatMessageReply _$ChatMessageReplyFromJson(Map<String, dynamic> json) =>
    _ChatMessageReply(
      parentMessageId: json['parent_message_id'] as String,
      parentMessageBody: json['parent_message_body'] as String,
      parentUserId: json['parent_user_id'] as String,
      parentUserName: json['parent_user_name'] as String,
      parentUserLogin: json['parent_user_login'] as String,
      threadMessageId: json['thread_message_id'] as String,
      threadUserId: json['thread_user_id'] as String,
      threadUserName: json['thread_user_name'] as String,
      threadUserLogin: json['thread_user_login'] as String,
    );

_ChatMessageBadge _$ChatMessageBadgeFromJson(Map<String, dynamic> json) =>
    _ChatMessageBadge(
      setId: json['set_id'] as String,
      id: json['id'] as String,
      info: json['info'] as String? ?? '',
    );
