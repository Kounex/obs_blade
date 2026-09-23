import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

import '../../../../../stores/views/kick_chat.dart';
import '../../../../../stores/views/kick_emotes.dart';
import '../../../../../stores/views/third_party_emotes.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../stores/views/twitch_emotes.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../types/classes/kick/kick_chat_message.dart';
import '../../../../../types/classes/twitch/eventsub/channel_chat_message.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/chat_autocomplete.dart';

/// Per-engine candidate feeds for the input's autocomplete strip. Read at
/// keystroke time (not reactive) — the strip recomputes on every edit.

bool _setting(SettingsKeys key) =>
    Hive.box(HiveKeys.Settings.name).get(key.name, defaultValue: true) == true;

/// Twitch: recent chatters; first-party channel/global emotes (what the
/// token may use) then 7TV/BTTV when enabled.
Iterable<ChatCompletionCandidate> twitchChatCompletions(
  ChatCompletionKind kind,
) {
  final chat = GetIt.instance<TwitchChatStore>();
  if (kind == ChatCompletionKind.mention) {
    return chatMentionCandidates([
      for (final message in chat.messages)
        (message.chatterUserLogin, message.chatterUserName),
    ], selfLogin: chat.user?.login);
  }
  final emotes = GetIt.instance<TwitchEmoteStore>();
  final broadcasterId = chat.user == null ? '' : chat.effectiveBroadcasterId;
  return [
    for (final emote in emotes.channelEmotes)
      ChatCompletionCandidate(
        label: emote.name,
        insertText: emote.name,
        imageUrl: twitchEmoteUrl(emote.id),
      ),
    for (final emote in emotes.globalEmotes)
      ChatCompletionCandidate(
        label: emote.name,
        insertText: emote.name,
        imageUrl: twitchEmoteUrl(emote.id),
      ),
    if (_setting(SettingsKeys.TwitchChatThirdPartyEmotes))
      for (final emote in GetIt.instance<ThirdPartyEmoteStore>().emotesFor(
        broadcasterId,
      ))
        ChatCompletionCandidate(
          label: emote.name,
          insertText: emote.name,
          imageUrl: emote.imageUrl,
        ),
  ];
}

/// Kick: recent chatters (slug-less usernames); Kick channel/global/emoji
/// catalog then 7TV when enabled.
Iterable<ChatCompletionCandidate> kickChatCompletions(ChatCompletionKind kind) {
  final chat = GetIt.instance<KickChatStore>();
  if (kind == ChatCompletionKind.mention) {
    return chatMentionCandidates([
      for (final message in chat.messages)
        if (message.sender?.username case final name?) (name, name),
    ], selfLogin: chat.selfUsername);
  }
  final broadcasterId = chat.channelInfo?.userId?.toString() ?? '';
  return [
    for (final section in GetIt.instance<KickEmoteStore>().sections)
      for (final emote in section.emotes)
        ChatCompletionCandidate(
          label: emote.name,
          insertText: emote.name,
          imageUrl: kickEmoteUrl(emote.id),
        ),
    if (_setting(SettingsKeys.KickChatThirdPartyEmotes))
      for (final emote in GetIt.instance<ThirdPartyEmoteStore>().emotesFor(
        broadcasterId,
      ))
        ChatCompletionCandidate(
          label: emote.name,
          insertText: emote.name,
          imageUrl: emote.imageUrl,
        ),
  ];
}

/// YouTube: recent chatters only — the Data API exposes no emote catalog.
Iterable<ChatCompletionCandidate> youTubeChatCompletions(
  ChatCompletionKind kind,
) {
  if (kind != ChatCompletionKind.mention) return const [];
  final chat = GetIt.instance<YouTubeChatStore>();
  return chatMentionCandidates([
    for (final message in chat.messages)
      if (message.authorName case final name?) (name, name),
  ], selfLogin: chat.selfChannelTitle);
}
