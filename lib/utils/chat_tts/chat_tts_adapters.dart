import '../../models/enums/chat_type.dart';
import '../../types/classes/kick/kick_chat_message.dart';
import '../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../types/classes/youtube/youtube_chat_message.dart';
import '../youtube/youtube_emoji.dart';
import 'chat_tts_utterance.dart';

/// Twitch EventSub row → [ChatTtsMessage]. Emote / cheermote fragments
/// become emote parts; moderator / broadcaster come from the badges.
ChatTtsMessage chatTtsFromTwitch(
  ChatMessageEvent event, {
  String? selfUserId,
  List<String?> selfNames = const [],
  bool Function(String word)? isThirdPartyEmote,
}) {
  final fragments = event.message.fragments;
  return ChatTtsMessage(
    id: event.messageId,
    platform: ChatType.Twitch,
    author: event.chatterUserName,
    authorNames: [event.chatterUserLogin, event.chatterUserName],
    parts: fragments.isEmpty
        ? [ChatTtsPart.text(event.message.text)]
        : [
            for (final fragment in fragments)
              fragment.type == 'emote' || fragment.type == 'cheermote'
                  ? ChatTtsPart.emote(fragment.text)
                  : ChatTtsPart.text(fragment.text),
          ],
    isModerator: event.badges.any((badge) => badge.setId == 'moderator'),
    isBroadcaster: event.badges.any((badge) => badge.setId == 'broadcaster'),
    isOwn: selfUserId != null && event.chatterUserId == selfUserId,
    selfNames: selfNames,
    isThirdPartyEmote: isThirdPartyEmote,
  );
}

/// YouTube row → [ChatTtsMessage], or null for rows that aren't chat
/// (memberships, polls, …). Super Chats are read with their message.
ChatTtsMessage? chatTtsFromYouTube(
  YouTubeChatMessage message, {
  String? selfChannelId,
  List<String?> selfNames = const [],
}) {
  if (message.type != YouTubeChatMessageType.textMessage &&
      message.type != YouTubeChatMessageType.superChat) {
    return null;
  }
  final author = message.authorName ?? '';
  return ChatTtsMessage(
    id: message.id,
    platform: ChatType.YouTube,
    author: author,
    authorNames: [author],
    parts: youTubeTtsParts(message.copyText),
    isModerator: message.isModerator,
    isBroadcaster: message.isOwner,
    isOwn: selfChannelId != null && message.authorChannelId == selfChannelId,
    selfNames: selfNames,
  );
}

/// YouTube text → parts: every `:code:` (YouTube's emojis and channels'
/// member emojis - the API sends only the code) is an emote part, so
/// "skip emotes" / emote-only rules apply instead of reading it out.
List<ChatTtsPart> youTubeTtsParts(String text) {
  final parts = <ChatTtsPart>[];
  var cursor = 0;
  for (final match in kYouTubeEmojiCodePattern.allMatches(text)) {
    if (match.start > cursor) {
      parts.add(ChatTtsPart.text(text.substring(cursor, match.start)));
    }
    final code = match.group(0)!;
    parts.add(ChatTtsPart.emote(code.substring(1, code.length - 1)));
    cursor = match.end;
  }
  if (cursor < text.length) parts.add(ChatTtsPart.text(text.substring(cursor)));
  return parts;
}

/// Kick row → [ChatTtsMessage]. `[emote:id:name]` tokens become emote
/// parts; moderator / broadcaster come from either badge generation.
ChatTtsMessage chatTtsFromKick(
  KickChatMessage message, {
  int? selfUserId,
  List<String?> selfNames = const [],
  bool Function(String word)? isThirdPartyEmote,
}) {
  final identity = message.sender?.identity;
  final badgeTypes = {
    for (final badge in identity?.badges ?? const <KickChatLegacyBadge>[])
      badge.type,
    for (final badge in identity?.badgesV2 ?? const <KickChatBadgeV2>[])
      badge.badgeType,
  };
  return ChatTtsMessage(
    id: message.id,
    platform: ChatType.Kick,
    author: message.authorName,
    authorNames: [message.sender?.username, message.sender?.slug],
    parts: [
      for (final fragment in parseKickChatContent(message.content))
        fragment.isEmote
            ? ChatTtsPart.emote(fragment.emoteName ?? '')
            : ChatTtsPart.text(fragment.text),
    ],
    isModerator: badgeTypes.contains('moderator'),
    isBroadcaster: badgeTypes.contains('broadcaster'),
    isOwn: selfUserId != null && message.authorId == selfUserId,
    selfNames: selfNames,
    isThirdPartyEmote: isThirdPartyEmote,
  );
}
