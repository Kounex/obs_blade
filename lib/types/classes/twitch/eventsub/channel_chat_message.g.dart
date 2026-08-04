// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessageEvent _$ChatMessageEventFromJson(Map<String, dynamic> json) =>
    _ChatMessageEvent(
      broadcasterUserId: json['broadcaster_user_id'] as String,
      chatterUserId: json['chatter_user_id'] as String,
      chatterUserLogin: json['chatter_user_login'] as String,
      chatterUserName: json['chatter_user_name'] as String,
      messageId: json['message_id'] as String,
      message: ChatMessageText.fromJson(
        json['message'] as Map<String, dynamic>,
      ),
      color: json['color'] as String?,
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
    );

_ChatFragmentEmote _$ChatFragmentEmoteFromJson(Map<String, dynamic> json) =>
    _ChatFragmentEmote(id: json['id'] as String);
